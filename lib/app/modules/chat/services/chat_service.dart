import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/chat/models/chat_message_model.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';

class ChatService extends GetxService with WidgetsBindingObserver {
  static const _usersCollection = 'chat_users';
  static const _roomsCollection = 'chat_rooms';
  static const _messagesCollection = 'messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  StreamSubscription<firebase_auth.User?>? _authSub;
  StreamSubscription<List<ChatRoomModel>>? _roomListSub;
  final Map<String, StreamSubscription<ChatMessageModel?>> _roomMessageSubs =
      {};
  final Map<String, String> _lastSeenMessageIdByRoom = {};
  final Set<String> _primedRooms = {};
  String? _activeNotificationUid;
  Timer? _presenceHeartbeat;
  static const Duration _presenceHeartbeatInterval = Duration(seconds: 30);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection(_roomsCollection);

  String? get currentUid => _auth.currentUser?.uid;

  bool get isLoggedIn => currentUid != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        stopChatNotifications();
      } else {
        startChatNotifications();
      }
    });
    if (currentUid != null) {
      startChatNotifications();
      _startPresenceHeartbeat();
      unawaited(updatePresence(isOnline: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentUid == null) return;
    if (state == AppLifecycleState.resumed) {
      _startPresenceHeartbeat();
      unawaited(updatePresence(isOnline: true));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopPresenceHeartbeat();
      unawaited(updatePresence(isOnline: false));
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(_presenceHeartbeatInterval, (_) {
      unawaited(updatePresence(isOnline: true));
    });
  }

  void _stopPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = null;
  }

  Future<void> ensureCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final displayName = _resolveCurrentDisplayName(currentUser);
    final username = _resolveCurrentUsername(currentUser);
    final userEmail = currentUser.email ?? '';
    final photoUrl = currentUser.photoURL ?? '';

    await _usersRef.doc(currentUser.uid).set({
      'uid': currentUser.uid,
      'display_name': displayName,
      'username': username,
      'email': userEmail,
      'photo_url': photoUrl,
      'is_online': true,
      'last_seen_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePresence({required bool isOnline}) async {
    final uid = currentUid;
    if (uid == null) return;
    await _usersRef.doc(uid).set({
      'is_online': isOnline,
      'last_seen_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<ChatUserModel?> streamUserById(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatUserModel.fromDoc(doc);
    });
  }

  Future<void> startChatNotifications() async {
    final uid = currentUid;
    if (uid == null) return;

    await ensureCurrentUserProfile();
    if (_activeNotificationUid == uid && _roomListSub != null) return;

    stopChatNotifications();
    _activeNotificationUid = uid;

    _roomListSub = streamCurrentUserRooms().listen((rooms) {
      final roomIds = rooms.map((room) => room.id).toSet();

      for (final room in rooms) {
        _listenForRoomLatestMessage(uid, room);
      }

      final staleRoomIds = _roomMessageSubs.keys
          .where((roomId) => !roomIds.contains(roomId))
          .toList();
      for (final roomId in staleRoomIds) {
        _roomMessageSubs.remove(roomId)?.cancel();
        _lastSeenMessageIdByRoom.remove(roomId);
        _primedRooms.remove(roomId);
      }
    });
  }

  void stopChatNotifications() {
    _roomListSub?.cancel();
    _roomListSub = null;
    _activeNotificationUid = null;
    for (final sub in _roomMessageSubs.values) {
      sub.cancel();
    }
    _roomMessageSubs.clear();
    _lastSeenMessageIdByRoom.clear();
    _primedRooms.clear();
  }

  Future<List<ChatUserModel>> searchUsers(
    String query, {
    int limit = 60,
  }) async {
    final uid = currentUid;
    if (uid == null) return const [];

    await ensureCurrentUserProfile();
    final normalizedQuery = query.trim().toLowerCase();
    final merged = <String, ChatUserModel>{};

    final localSnapshot = await _usersRef.limit(limit * 4).get();
    for (final doc in localSnapshot.docs) {
      final user = ChatUserModel.fromDoc(doc);
      if (user.uid == uid) continue;
      if (!_matchesUserQuery(user, normalizedQuery)) continue;
      merged[user.uid] = user;
    }

    final backendUsers = await _searchUsersFromBackend(
      normalizedQuery,
      limit: limit,
    );
    for (final user in backendUsers) {
      if (user.uid == uid) continue;
      if (!_matchesUserQuery(user, normalizedQuery)) continue;
      merged[user.uid] = user;
    }

    final leaderboardUsers = await _searchUsersFromLeaderboard(
      normalizedQuery,
      limit: limit * 2,
    );
    for (final user in leaderboardUsers) {
      if (user.uid == uid) continue;
      if (!_matchesUserQuery(user, normalizedQuery)) continue;
      merged[user.uid] = user;
    }

    final users = merged.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    if (users.isNotEmpty) {
      await _upsertUsersToFirestore(users);
    }

    return users.take(limit).toList();
  }

  Future<List<ChatUserModel>> recentChatUsers({int limit = 60}) async {
    final uid = currentUid;
    if (uid == null) return const [];

    await ensureCurrentUserProfile();

    try {
      final snapshot = await _roomsRef
          .where('members', arrayContains: uid)
          .limit(limit * 3)
          .get();

      final rooms = snapshot.docs.map(ChatRoomModel.fromDoc).toList()
        ..sort((a, b) {
          final aTime = a.lastMessageAt ?? a.updatedAt;
          final bTime = b.lastMessageAt ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

      final orderedUserIds = <String>[];
      final fallbackNames = <String, String>{};

      for (final room in rooms) {
        if (room.type != 'direct') continue;

        final hasMessage =
            room.lastMessage.trim().isNotEmpty || room.lastMessageAt != null;
        if (!hasMessage) continue;

        final otherUserId = room.members.firstWhere(
          (memberId) => memberId != uid,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) continue;

        if (!orderedUserIds.contains(otherUserId)) {
          orderedUserIds.add(otherUserId);
          final fallbackName = (room.memberNames[otherUserId] ?? '').trim();
          if (fallbackName.isNotEmpty) {
            fallbackNames[otherUserId] = fallbackName;
          }
        }

        if (orderedUserIds.length >= limit) break;
      }

      if (orderedUserIds.isEmpty) return const [];

      final usersById = <String, ChatUserModel>{};
      const chunkSize = 10; // Firestore whereIn supports max 10 values.

      for (var i = 0; i < orderedUserIds.length; i += chunkSize) {
        final end = math.min(i + chunkSize, orderedUserIds.length);
        final chunk = orderedUserIds.sublist(i, end);
        final usersSnapshot = await _usersRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in usersSnapshot.docs) {
          final user = ChatUserModel.fromDoc(doc);
          if (user.uid == uid) continue;
          usersById[user.uid] = user;
        }
      }

      final now = DateTime.now();
      final users = <ChatUserModel>[];
      for (final userId in orderedUserIds) {
        if (userId == uid) continue;

        final storedUser = usersById[userId];
        if (storedUser != null) {
          users.add(storedUser);
          continue;
        }

        final fallbackName = fallbackNames[userId] ?? 'Player';
        users.add(
          ChatUserModel(
            uid: userId,
            displayName: fallbackName,
            username: _usernameFromDisplayName(fallbackName),
            email: '',
            photoUrl: '',
            isOnline: false,
            updatedAt: now,
            lastSeenAt: null,
          ),
        );
      }

      return users.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Stream<List<ChatUserModel>> streamAllUsers() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _usersRef.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map(ChatUserModel.fromDoc)
          .where((user) => user.uid != uid)
          .toList();

      users.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return users;
    });
  }

  Stream<List<ChatRoomModel>> streamCurrentUserRooms() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _roomsRef.where('members', arrayContains: uid).snapshots().map((s) {
      final rooms = s.docs.map(ChatRoomModel.fromDoc).toList();
      rooms.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
      return rooms;
    });
  }

  Stream<ChatRoomModel?> streamRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatRoomModel.fromDoc(doc);
    });
  }

  Stream<List<ChatMessageModel>> streamRoomMessages(
    String roomId, {
    int limit = 200,
  }) {
    return _roomsRef
        .doc(roomId)
        .collection(_messagesCollection)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map(ChatMessageModel.fromDoc).toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          unawaited(markRoomMessagesSeen(roomId));
          return messages;
        });
  }

  Stream<ChatMessageModel?> streamRoomLatestMessage(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection(_messagesCollection)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ChatMessageModel.fromDoc(snapshot.docs.first);
        });
  }

  Future<ChatRoomModel?> getRoomById(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return ChatRoomModel.fromDoc(doc);
  }

  Future<String> getOrCreateDirectRoom({
    required ChatUserModel otherUser,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }
    if (uid == otherUser.uid) {
      throw Exception('Cannot create a chat with yourself.');
    }

    await ensureCurrentUserProfile();

    final sortedMembers = [uid, otherUser.uid]..sort();
    final roomId = 'dm_${sortedMembers[0]}_${sortedMembers[1]}';

    final roomRef = _roomsRef.doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      final meName = await _resolveCurrentUserNameFromStore(uid);
      await roomRef.set({
        'id': roomId,
        'type': 'direct',
        'name': '',
        'image_url': '',
        'members': sortedMembers,
        'admins': [uid],
        'member_names': {uid: meName, otherUser.uid: otherUser.displayName},
        'created_by': uid,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'client_created_at': DateTime.now().toIso8601String(),
        'client_updated_at': DateTime.now().toIso8601String(),
        'last_message': '',
        'last_message_sender_id': '',
        'last_message_at': null,
      });
    }

    return roomId;
  }

  Future<String> createGroupRoom({
    required String name,
    required List<ChatUserModel> selectedUsers,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }

    await ensureCurrentUserProfile();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Group name is required.');
    }

    final uniqueMembers = <String>{uid};
    final memberNames = <String, String>{};
    memberNames[uid] = await _resolveCurrentUserNameFromStore(uid);

    for (final user in selectedUsers) {
      uniqueMembers.add(user.uid);
      memberNames[user.uid] = user.displayName;
    }

    if (uniqueMembers.length < 2) {
      throw Exception('Select at least one participant.');
    }

    final roomRef = _roomsRef.doc();
    await roomRef.set({
      'id': roomRef.id,
      'type': 'group',
      'name': trimmedName,
      'image_url': '',
      'members': uniqueMembers.toList(),
      'admins': [uid],
      'member_names': memberNames,
      'created_by': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().toIso8601String(),
      'client_updated_at': DateTime.now().toIso8601String(),
      'last_message': '',
      'last_message_sender_id': '',
      'last_message_at': null,
    });

    return roomRef.id;
  }

  Future<void> updateGroupName({
    required String roomId,
    required String newName,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Group name cannot be empty.');
    }

    final roomRef = _roomsRef.doc(roomId);
    await _firestore.runTransaction<void>((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) {
        throw Exception('Group not found.');
      }

      final room = ChatRoomModel.fromDoc(roomDoc);
      if (!room.isGroup) {
        throw Exception('This chat is not a group.');
      }
      if (!room.admins.contains(uid)) {
        throw Exception('Only group admins can edit the group name.');
      }

      transaction.set(roomRef, {
        'name': trimmedName,
        'updated_at': FieldValue.serverTimestamp(),
        'client_updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  Future<int> addGroupMembers({
    required String roomId,
    required List<ChatUserModel> users,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }
    if (users.isEmpty) return 0;

    final dedupedUsers = <String, ChatUserModel>{};
    for (final user in users) {
      final memberId = user.uid.trim();
      if (memberId.isEmpty || memberId == uid) continue;
      dedupedUsers[memberId] = user;
    }
    if (dedupedUsers.isEmpty) return 0;

    final meName = await _resolveCurrentUserNameFromStore(uid);
    final roomRef = _roomsRef.doc(roomId);
    return _firestore.runTransaction<int>((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) {
        throw Exception('Group not found.');
      }

      final room = ChatRoomModel.fromDoc(roomDoc);
      if (!room.isGroup) {
        throw Exception('This chat is not a group.');
      }
      if (!room.admins.contains(uid)) {
        throw Exception('Only group admins can invite members.');
      }

      final members = room.members.toSet();
      final memberNames = Map<String, String>.from(room.memberNames);
      memberNames[uid] = meName;

      final addableIds = dedupedUsers.keys
          .where((memberId) => !members.contains(memberId))
          .toList();
      if (addableIds.isEmpty) return 0;

      for (final memberId in addableIds) {
        members.add(memberId);
        memberNames[memberId] = dedupedUsers[memberId]!.displayName.trim();
      }

      transaction.set(roomRef, {
        'members': members.toList(),
        'member_names': memberNames,
        'updated_at': FieldValue.serverTimestamp(),
        'client_updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      return addableIds.length;
    });
  }

  Future<void> removeGroupMember({
    required String roomId,
    required String memberId,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }

    final targetId = memberId.trim();
    if (targetId.isEmpty) {
      throw Exception('Invalid member selected.');
    }

    final roomRef = _roomsRef.doc(roomId);
    await _firestore.runTransaction<void>((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) {
        throw Exception('Group not found.');
      }

      final room = ChatRoomModel.fromDoc(roomDoc);
      if (!room.isGroup) {
        throw Exception('This chat is not a group.');
      }

      final isSelfRemoval = targetId == uid;
      final isCurrentUserAdmin = room.admins.contains(uid);
      if (!isSelfRemoval && !isCurrentUserAdmin) {
        throw Exception('Only group admins can remove members.');
      }

      if (!room.members.contains(targetId)) return;

      final members = room.members.where((id) => id != targetId).toList();
      if (members.isEmpty) {
        transaction.delete(roomRef);
        return;
      }

      final admins = room.admins.where((id) => id != targetId).toSet();
      if (admins.isEmpty) {
        admins.add(members.first);
      }

      final memberNames = Map<String, String>.from(room.memberNames)
        ..remove(targetId);

      transaction.set(roomRef, {
        'members': members,
        'admins': admins.toList(),
        'member_names': memberNames,
        'updated_at': FieldValue.serverTimestamp(),
        'client_updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> leaveGroup(String roomId) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to continue chatting.');
    }
    await removeGroupMember(roomId: roomId, memberId: uid);
  }

  Future<void> sendTextMessage({
    required String roomId,
    required String text,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to send messages.');
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final senderName = await _resolveCurrentUserNameFromStore(uid);
    final roomRef = _roomsRef.doc(roomId);
    final messageRef = roomRef.collection(_messagesCollection).doc();
    final now = DateTime.now().toIso8601String();

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'id': messageRef.id,
      'room_id': roomId,
      'sender_id': uid,
      'sender_name': senderName,
      'text': trimmedText,
      'type': 'text',
      'seen_by': [uid],
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': now,
    });

    batch.set(roomRef, {
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': now,
      'last_message': trimmedText,
      'last_message_sender_id': uid,
      'last_message_at': FieldValue.serverTimestamp(),
      'client_last_message_at': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> markRoomMessagesSeen(String roomId) async {
    final uid = currentUid;
    if (uid == null) return;
    final snap = await _roomsRef
        .doc(roomId)
        .collection(_messagesCollection)
        .orderBy('created_at', descending: true)
        .limit(40)
        .get();
    final batch = _firestore.batch();
    var changed = false;
    for (final doc in snap.docs) {
      final data = doc.data();
      final senderId = (data['sender_id'] ?? '').toString();
      if (senderId == uid) continue;
      final seenBy = ((data['seen_by'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      if (seenBy.contains(uid)) continue;
      batch.set(doc.reference, {
        'seen_by': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
      changed = true;
    }
    if (changed) {
      await batch.commit();
    }
  }

  Future<void> setTyping({
    required String roomId,
    required bool isTyping,
  }) async {
    final uid = currentUid;
    if (uid == null) return;
    await _roomsRef.doc(roomId).set({
      'typing_uids': isTyping
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenForRoomLatestMessage(String currentUidValue, ChatRoomModel room) {
    if (_roomMessageSubs.containsKey(room.id)) return;

    _roomMessageSubs[room.id] = streamRoomLatestMessage(room.id).listen((
      message,
    ) {
      if (message == null) return;

      final previousMessageId = _lastSeenMessageIdByRoom[room.id];
      final alreadyPrimed = _primedRooms.contains(room.id);

      _lastSeenMessageIdByRoom[room.id] = message.id;
      if (!alreadyPrimed) {
        _primedRooms.add(room.id);
        return;
      }
      if (previousMessageId == message.id) return;
      if (message.senderId == currentUidValue) return;

      _notifyIncomingMessage(
        room: room,
        message: message,
        currentUidValue: currentUidValue,
      );
    });
  }

  void _notifyIncomingMessage({
    required ChatRoomModel room,
    required ChatMessageModel message,
    required String currentUidValue,
  }) {
    if (!Get.isRegistered<NotificationController>()) return;
    final notificationController = Get.find<NotificationController>();

    final title = room.displayTitleFor(currentUidValue);
    final body = message.text.trim().isEmpty ? 'New message' : message.text;
    notificationController.showChatNotification(
      title: title,
      body: body,
      payload: 'chat:${room.id}',
    );
  }

  Future<List<ChatUserModel>> _searchUsersFromBackend(
    String normalizedQuery, {
    required int limit,
  }) async {
    try {
      final dio = await locator<NetworkProvider>().auth();
      final response = await dio.get(
        '',
        queryParameters: {
          'search': normalizedQuery,
          'q': normalizedQuery,
          'username': normalizedQuery,
          'email': normalizedQuery,
          'limit': limit,
          'page': 1,
        },
      );

      final usersRaw = _extractUsersPayload(response.data);
      final users = <ChatUserModel>[];
      for (final raw in usersRaw) {
        final user = _chatUserFromBackendMap(raw);
        if (user != null) {
          users.add(user);
        }
      }

      if (users.isNotEmpty) {
        await _upsertUsersToFirestore(users);
      }

      return users;
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<ChatUserModel>> _searchUsersFromLeaderboard(
    String normalizedQuery, {
    required int limit,
  }) async {
    try {
      final snap = await _firestore
          .collection('mini_game_leaderboard')
          .limit(limit)
          .get();

      final users = <ChatUserModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = _firstNonEmpty([
          (data['userId'] ?? '').toString(),
          doc.id,
        ], fallback: '');
        if (uid.isEmpty) continue;

        final displayName = _firstNonEmpty([
          (data['displayName'] ?? '').toString(),
          (data['username'] ?? '').toString(),
        ], fallback: 'Player');
        final username = _firstNonEmpty([
          (data['username'] ?? '').toString(),
          _usernameFromDisplayName(displayName),
        ], fallback: '');
        final photoUrl = (data['avatarUrl'] ?? '').toString().trim();

        final user = ChatUserModel(
          uid: uid,
          displayName: displayName,
          username: username,
          email: '',
          photoUrl: photoUrl,
          isOnline: false,
          updatedAt: DateTime.now(),
          lastSeenAt: null,
        );

        if (_matchesUserQuery(user, normalizedQuery)) {
          users.add(user);
        }
      }

      return users;
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _extractUsersPayload(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (payload is! Map) return const [];

    final map = Map<String, dynamic>.from(payload);
    for (final key in ['users', 'data', 'results', 'items']) {
      final value = map[key];
      if (value is List) {
        return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    }

    final singleUser = map['user'];
    if (singleUser is Map) {
      return [Map<String, dynamic>.from(singleUser)];
    }

    return const [];
  }

  ChatUserModel? _chatUserFromBackendMap(Map<String, dynamic> raw) {
    final uid = _firstNonEmpty([
      _readNested(raw, ['fid'])?.toString(),
      _readNested(raw, ['uid'])?.toString(),
      _readNested(raw, ['firebase_uid'])?.toString(),
      _readNested(raw, ['firebaseUid'])?.toString(),
      _readNested(raw, ['firebase_id'])?.toString(),
      _readNested(raw, ['firebaseId'])?.toString(),
    ], fallback: '');

    if (uid == 'Player' || uid.trim().isEmpty) {
      return null;
    }

    final username = _firstNonEmpty([
      _readNested(raw, ['gameUserName'])?.toString(),
      _readNested(raw, ['username'])?.toString(),
      _readNested(raw, ['user_name'])?.toString(),
      _readNested(raw, ['displayName'])?.toString(),
      _readNested(raw, ['display_name'])?.toString(),
      _readNested(raw, ['name'])?.toString(),
    ], fallback: '');

    final displayName = _firstNonEmpty([
      _readNested(raw, ['name'])?.toString(),
      _readNested(raw, ['display_name'])?.toString(),
      _readNested(raw, ['displayName'])?.toString(),
      username,
      _readNested(raw, [
        'contact',
        'electronicAddress',
        'emailId',
      ])?.toString().split('@').first,
    ], fallback: 'Player');

    final email = _firstNonEmpty([
      _readNested(raw, ['email'])?.toString(),
      _readNested(raw, ['contact', 'electronicAddress', 'emailId'])?.toString(),
    ], fallback: '');

    final photoUrl = _firstNonEmpty([
      _readNested(raw, ['photoUrl'])?.toString(),
      _readNested(raw, ['photo_url'])?.toString(),
      _readNested(raw, ['avatarUrl'])?.toString(),
      _readNested(raw, ['avatar_url'])?.toString(),
    ], fallback: '');

    return ChatUserModel(
      uid: uid.trim(),
      displayName: displayName.trim(),
      username: username.trim().isEmpty
          ? _usernameFromDisplayName(displayName)
          : username.trim(),
      email: email.trim(),
      photoUrl: photoUrl.trim(),
      backendUserId: _parseInt(
        _readNested(raw, ['id']) ?? _readNested(raw, ['user_id']),
      ),
      isOnline: false,
      updatedAt: DateTime.now(),
      lastSeenAt: null,
    );
  }

  dynamic _readNested(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  Future<void> _upsertUsersToFirestore(List<ChatUserModel> users) async {
    final batch = _firestore.batch();
    for (final user in users) {
      batch.set(_usersRef.doc(user.uid), {
        'uid': user.uid,
        'display_name': user.displayName,
        'username': user.username,
        'email': user.email,
        'photo_url': user.photoUrl,
        'is_online': user.isOnline,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  bool _matchesUserQuery(ChatUserModel user, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final needle = _normalizeSearchToken(normalizedQuery);
    if (needle.isEmpty) return true;

    final candidates = [user.displayName, user.username, user.email];
    for (final candidate in candidates) {
      if (_normalizeSearchToken(candidate).contains(needle)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeSearchToken(String value) {
    return value.trim().toLowerCase().replaceAll('@', '');
  }

  String _usernameFromDisplayName(String displayName) {
    final cleaned = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned;
  }

  Future<String> _resolveCurrentUserNameFromStore(String uid) async {
    final profileDoc = await _usersRef.doc(uid).get();
    if (profileDoc.exists) {
      final fromProfile = (profileDoc.data()?['display_name'] ?? '').toString();
      if (fromProfile.trim().isNotEmpty) {
        return fromProfile.trim();
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'Player';
    return _resolveCurrentDisplayName(currentUser);
  }

  String _resolveCurrentDisplayName(firebase_auth.User currentUser) {
    String? gameName;
    String? fullName;

    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      gameName = userController.user.value.gameUserName;
      fullName = userController.user.value.name;
    }

    final fallbackFromEmail = currentUser.email?.split('@').first;

    return _firstNonEmpty([
      gameName,
      fullName,
      currentUser.displayName,
      fallbackFromEmail,
      'Player',
    ]);
  }

  String _resolveCurrentUsername(firebase_auth.User currentUser) {
    String? gameName;
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      gameName = userController.user.value.gameUserName;
    }

    final fallbackFromEmail = currentUser.email?.split('@').first;
    return _firstNonEmpty([
      gameName,
      currentUser.displayName,
      fallbackFromEmail,
    ], fallback: '');
  }

  String _firstNonEmpty(List<String?> values, {String fallback = 'Player'}) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPresenceHeartbeat();
    unawaited(updatePresence(isOnline: false));
    _authSub?.cancel();
    stopChatNotifications();
    super.onClose();
  }
}
