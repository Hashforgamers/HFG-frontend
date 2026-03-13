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
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService extends GetxService with WidgetsBindingObserver {
  static const _usersCollection = 'chat_users';
  static const _roomsCollection = 'chat_rooms';
  static const _messagesCollection = 'messages';
  static const _hiddenRecentUsersKeyPrefix = 'chat_hidden_recent_users_';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final SharedPreferences _prefs = locator<SharedPreferences>();
  StreamSubscription<firebase_auth.User?>? _authSub;
  StreamSubscription<List<ChatRoomModel>>? _roomListSub;
  final Map<String, StreamSubscription<ChatMessageModel?>> _roomMessageSubs =
      {};
  final Map<String, String> _lastSeenMessageIdByRoom = {};
  final Set<String> _primedRooms = {};
  final Map<String, bool> _unreadRoomById = {};
  String? _activeNotificationUid;
  Timer? _presenceHeartbeat;
  static const Duration _presenceHeartbeatInterval = Duration(seconds: 30);
  final RxInt unreadRoomCount = 0.obs;
  DateTime _sessionStartedAt = DateTime.now();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection(_roomsCollection);

  String? get currentUid => _auth.currentUser?.uid;

  bool get isLoggedIn => currentUid != null;

  @override
  void onInit() {
    super.onInit();
    _sessionStartedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _trackInactivityIfNeeded();
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
      _sessionStartedAt = DateTime.now();
      _startPresenceHeartbeat();
      unawaited(updatePresence(isOnline: true));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      final uid = currentUid ?? '';
      final durationSeconds = DateTime.now()
          .difference(_sessionStartedAt)
          .inSeconds;
      _segmentService.onCustomEvent('App Backgrounded', {
        'current_screen': 'chat_service',
      });
      _fbEventsService.onAppBackgrounded(currentScreen: 'chat_service');
      _segmentService.onCustomEvent('Session Duration', {
        'user_id': uid,
        'duration_seconds': durationSeconds,
      });
      _fbEventsService.onSessionDuration(
        userId: uid,
        durationSeconds: durationSeconds,
      );
      _segmentService.onCustomEvent('Session Ended', {
        'user_id': uid,
        'source': 'background',
      });
      _fbEventsService.onSessionEnded(userId: uid, source: 'background');
      _prefs.setInt('last_active_at_ms', DateTime.now().millisecondsSinceEpoch);
      _stopPresenceHeartbeat();
      unawaited(updatePresence(isOnline: false));
    }
  }

  void _trackInactivityIfNeeded() {
    final uid = currentUid ?? '';
    if (uid.isEmpty) return;
    final lastActiveMs = _prefs.getInt('last_active_at_ms');
    if (lastActiveMs == null || lastActiveMs <= 0) return;
    final inactiveFor = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastActiveMs),
    );
    if (inactiveFor >= const Duration(days: 7)) {
      _segmentService.onCustomEvent('User Inactive 7d', {'user_id': uid});
      _fbEventsService.onUserInactive7d(userId: uid);
      return;
    }
    if (inactiveFor >= const Duration(days: 3)) {
      _segmentService.onCustomEvent('User Inactive 3d', {'user_id': uid});
      _fbEventsService.onUserInactive3d(userId: uid);
      return;
    }
    if (inactiveFor >= const Duration(hours: 24)) {
      _segmentService.onCustomEvent('User Inactive 24h', {'user_id': uid});
      _fbEventsService.onUserInactive24h(userId: uid);
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
        _unreadRoomById.remove(roomId);
      }
      _recomputeUnreadRoomCount();
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
    _unreadRoomById.clear();
    unreadRoomCount.value = 0;
  }

  Future<List<ChatUserModel>> searchUsers(
    String query, {
    int limit = 60,
  }) async {
    final uid = currentUid;
    if (uid == null) return const [];

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    final backendUsers = await _searchUsersFromBackend(
      query.trim(),
      limit: limit,
    );

    final users =
        backendUsers
            .where((user) => user.uid != uid)
            .where((user) => _matchesUserQuery(user, normalizedQuery))
            .toList()
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

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
        if (room.deletedForUserIds.contains(uid)) continue;

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

      final hiddenUserIds = await _hiddenRecentUserIds();
      final visibleUserIds = orderedUserIds
          .where((id) => !hiddenUserIds.contains(id))
          .toList();

      if (visibleUserIds.isEmpty) return const [];

      final usersById = <String, ChatUserModel>{};
      const chunkSize = 10; // Firestore whereIn supports max 10 values.

      for (var i = 0; i < visibleUserIds.length; i += chunkSize) {
        final end = math.min(i + chunkSize, visibleUserIds.length);
        final chunk = visibleUserIds.sublist(i, end);
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
      for (final userId in visibleUserIds) {
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
            phoneNumber: '',
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

  Future<void> removeUserFromRecentSearchHistory(String targetUid) async {
    final uid = currentUid;
    final target = targetUid.trim();
    if (uid == null || target.isEmpty) return;

    final key = _hiddenRecentUsersKey(uid);
    final current = _prefs.getStringList(key) ?? const <String>[];
    if (current.contains(target)) return;
    await _prefs.setStringList(key, <String>[...current, target]);
  }

  Future<void> clearRecentSearchHistory() async {
    final uid = currentUid;
    if (uid == null) return;
    await _prefs.remove(_hiddenRecentUsersKey(uid));
  }

  Future<Set<String>> _hiddenRecentUserIds() async {
    final uid = currentUid;
    if (uid == null) return const <String>{};
    final values = _prefs.getStringList(_hiddenRecentUsersKey(uid)) ?? const [];
    return values.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  String _hiddenRecentUsersKey(String uid) =>
      '$_hiddenRecentUsersKeyPrefix$uid';

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
      final rooms = s.docs
          .map(ChatRoomModel.fromDoc)
          .where((room) => !room.deletedForUserIds.contains(uid))
          .toList();
      rooms.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
      return rooms;
    });
  }

  Future<void> deleteRoomForCurrentUser(String roomId) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to manage chats.');
    }

    await _roomsRef.doc(roomId).set({
      'deleted_for_uids': FieldValue.arrayUnion([uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    _unreadRoomById.remove(roomId);
    _recomputeUnreadRoomCount();
  }

  Future<void> restoreRoomForCurrentUser(String roomId) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to manage chats.');
    }

    await _roomsRef.doc(roomId).set({
      'deleted_for_uids': FieldValue.arrayRemove([uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> setRoomMutedForCurrentUser({
    required String roomId,
    required bool muted,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to manage chats.');
    }
    await _roomsRef.doc(roomId).set({
      'muted_uids': muted
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> setRoomArchivedForCurrentUser({
    required String roomId,
    required bool archived,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to manage chats.');
    }
    await _roomsRef.doc(roomId).set({
      'archived_uids': archived
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
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

    final existingSnapshot = await _roomsRef
        .where('members', arrayContains: uid)
        .limit(150)
        .get();

    ChatRoomModel? activeDirectRoom;
    final candidates = existingSnapshot.docs.map(ChatRoomModel.fromDoc);
    for (final room in candidates) {
      if (room.type != 'direct') continue;
      if (!room.members.contains(otherUser.uid)) continue;
      if (room.deletedForUserIds.contains(uid)) continue;

      if (activeDirectRoom == null) {
        activeDirectRoom = room;
        continue;
      }
      final currentTime =
          activeDirectRoom.lastMessageAt ?? activeDirectRoom.updatedAt;
      final roomTime = room.lastMessageAt ?? room.updatedAt;
      if (roomTime.isAfter(currentTime)) {
        activeDirectRoom = room;
      }
    }

    final meName = await _resolveCurrentUserNameFromStore(uid);

    if (activeDirectRoom != null) {
      await _roomsRef.doc(activeDirectRoom.id).set({
        'member_names': {uid: meName, otherUser.uid: otherUser.displayName},
        'updated_at': FieldValue.serverTimestamp(),
        'client_updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return activeDirectRoom.id;
    }

    final roomRef = _roomsRef.doc();
    await roomRef.set({
      'id': roomRef.id,
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
      'muted_uids': const <String>[],
      'archived_uids': const <String>[],
      'deleted_for_uids': const <String>[],
    });

    return roomRef.id;
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

  Future<void> sendTeamInviteMessage({
    required String roomId,
    required String eventId,
    required String teamId,
    required String teamName,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to send invites.');
    }

    final safeEventId = eventId.trim();
    final safeTeamId = teamId.trim();
    final safeTeamName = teamName.trim().isEmpty ? 'Team' : teamName.trim();
    if (safeEventId.isEmpty || safeTeamId.isEmpty) {
      throw Exception('Invalid team details for sharing.');
    }

    final senderName = await _resolveCurrentUserNameFromStore(uid);
    final roomRef = _roomsRef.doc(roomId);
    final messageRef = roomRef.collection(_messagesCollection).doc();
    final now = DateTime.now().toIso8601String();
    final previewText = '$senderName shared a team invite: $safeTeamName';

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'id': messageRef.id,
      'room_id': roomId,
      'sender_id': uid,
      'sender_name': senderName,
      'text': previewText,
      'type': 'team_invite',
      'meta': {
        'event_id': safeEventId,
        'team_id': safeTeamId,
        'team_name': safeTeamName,
        'inviter_uid': uid,
      },
      'seen_by': [uid],
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': now,
    });

    batch.set(roomRef, {
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': now,
      'last_message': 'Team invite: $safeTeamName',
      'last_message_sender_id': uid,
      'last_message_at': FieldValue.serverTimestamp(),
      'client_last_message_at': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> sendArenaBookingInviteMessage({
    required String roomId,
    required String cafeName,
    required String consoleType,
    required String bookingDate,
    required int playerCount,
    required List<int> bookingIds,
    required List<Map<String, dynamic>> slots,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Please sign in to share bookings.');
    }

    final safeCafeName = cafeName.trim().isEmpty ? 'Gaming Cafe' : cafeName.trim();
    final safeConsoleType = consoleType.trim().isEmpty ? 'Setup' : consoleType.trim();
    final safeBookingDate = bookingDate.trim();
    if (safeBookingDate.isEmpty || bookingIds.isEmpty) {
      throw Exception('Invalid booking details for sharing.');
    }

    final senderName = await _resolveCurrentUserNameFromStore(uid);
    final roomRef = _roomsRef.doc(roomId);
    final messageRef = roomRef.collection(_messagesCollection).doc();
    final now = DateTime.now().toIso8601String();

    final slotLabels = slots
        .map((slot) {
          final start = (slot['start_time'] ?? '').toString().trim();
          final end = (slot['end_time'] ?? '').toString().trim();
          if (start.isEmpty || end.isEmpty) return '';
          return '$start - $end';
        })
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    final previewText =
        '$senderName shared a squad booking for $safeCafeName';

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'id': messageRef.id,
      'room_id': roomId,
      'sender_id': uid,
      'sender_name': senderName,
      'text': previewText,
      'type': 'arena_booking_invite',
      'meta': {
        'cafe_name': safeCafeName,
        'console_type': safeConsoleType,
        'booking_date': safeBookingDate,
        'player_count': playerCount,
        'booking_ids': bookingIds,
        'slots': slots,
        'slot_labels': slotLabels,
        'shared_by_uid': uid,
      },
      'seen_by': [uid],
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': now,
    });

    batch.set(roomRef, {
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': now,
      'last_message': 'Squad booking: $safeCafeName',
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
    if (_unreadRoomById[roomId] == true) {
      _unreadRoomById[roomId] = false;
      _recomputeUnreadRoomCount();
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

  Future<int?> resolveCurrentBackendUserId() async {
    if (Get.isRegistered<UserController>()) {
      final controller = Get.find<UserController>();
      final fromController = _parseInt(controller.userId);
      if (fromController != null && fromController > 0) {
        return fromController;
      }
    }

    final fid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (fid.isNotEmpty) {
      final apiUser = await _remoteRepo.checkUserExistsInAPI(fid);
      final fromApi = _parseInt(
        _readNested(apiUser ?? const <String, dynamic>{}, ['id']) ??
            _readNested(apiUser ?? const <String, dynamic>{}, ['user_id']),
      );
      if (fromApi != null && fromApi > 0) {
        return fromApi;
      }
    }

    final userData = await _remoteRepo.getUserFromPreferences();
    final fromUserData = _parseInt(
      _readNested(userData ?? const <String, dynamic>{}, ['id']) ??
          _readNested(userData ?? const <String, dynamic>{}, ['user_id']),
    );
    if (fromUserData != null && fromUserData > 0) {
      return fromUserData;
    }

    return null;
  }

  void _listenForRoomLatestMessage(String currentUidValue, ChatRoomModel room) {
    if (_roomMessageSubs.containsKey(room.id)) return;

    _roomMessageSubs[room.id] = streamRoomLatestMessage(room.id).listen((
      message,
    ) {
      if (message == null) return;

      final isUnreadForCurrentUser =
          message.senderId != currentUidValue &&
          !message.seenBy.contains(currentUidValue);
      _unreadRoomById[room.id] = isUnreadForCurrentUser;
      _recomputeUnreadRoomCount();

      final previousMessageId = _lastSeenMessageIdByRoom[room.id];
      final alreadyPrimed = _primedRooms.contains(room.id);

      _lastSeenMessageIdByRoom[room.id] = message.id;
      if (!alreadyPrimed) {
        _primedRooms.add(room.id);
        if (_shouldNotifyPrimedMessage(
          room: room,
          message: message,
          currentUidValue: currentUidValue,
        )) {
          _notifyIncomingMessage(
            room: room,
            message: message,
            currentUidValue: currentUidValue,
          );
        }
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

  bool _shouldNotifyPrimedMessage({
    required ChatRoomModel room,
    required ChatMessageModel message,
    required String currentUidValue,
  }) {
    if (message.senderId == currentUidValue) return false;
    if (message.seenBy.contains(currentUidValue)) return false;
    final age = DateTime.now().difference(message.createdAt);
    if (age > const Duration(seconds: 30)) return false;
    return room.lastMessageSenderId == message.senderId;
  }

  void _recomputeUnreadRoomCount() {
    unreadRoomCount.value = _unreadRoomById.values.where((v) => v).length;
  }

  void _notifyIncomingMessage({
    required ChatRoomModel room,
    required ChatMessageModel message,
    required String currentUidValue,
  }) {
    if (room.mutedUserIds.contains(currentUidValue)) return;
    if (!Get.isRegistered<NotificationController>()) return;
    final notificationController = Get.find<NotificationController>();

    final title = room.displayTitleFor(currentUidValue);
    final body = _notificationBodyForMessage(message);
    notificationController.showChatNotification(
      title: title,
      body: body,
      payload: 'chat:${room.id}',
    );
  }

  String _notificationBodyForMessage(ChatMessageModel message) {
    if (message.type == 'arena_booking_invite') {
      final cafeName = (message.meta['cafe_name'] ?? '').toString().trim();
      if (cafeName.isNotEmpty) {
        return '${message.senderName} shared a squad booking for $cafeName';
      }
      return '${message.senderName} shared a squad booking with you';
    }
    final body = message.text.trim();
    return body.isEmpty ? 'New message' : body;
  }

  Future<List<ChatUserModel>> _searchUsersFromBackend(
    String query, {
    required int limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final safeLimit = limit.clamp(1, 50);
    try {
      final dio = await locator<NetworkProvider>().auth();
      final response = await dio.get(
        ApiEndpoints.userSearch,
        queryParameters: {'q': q, 'limit': safeLimit, 'page': 1},
      );

      final usersRaw = _extractUsersPayload(response.data);
      final users = <ChatUserModel>[];
      for (final raw in usersRaw) {
        final user = _chatUserFromBackendMap(raw);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } on DioException {
      return const [];
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
    final phoneNumber = _firstNonEmpty([
      _readNested(raw, ['phone'])?.toString(),
      _readNested(raw, ['phone_number'])?.toString(),
      _readNested(raw, ['mobile'])?.toString(),
      _readNested(raw, ['mobileNo'])?.toString(),
      _readNested(raw, ['mobile_number'])?.toString(),
      _readNested(raw, ['contact', 'electronicAddress', 'mobileNo'])
          ?.toString(),
    ], fallback: '');

    final photoUrl = _firstNonEmpty([
      _readNested(raw, ['photoUrl'])?.toString(),
      _readNested(raw, ['photo_url'])?.toString(),
      _readNested(raw, ['avatarUrl'])?.toString(),
      _readNested(raw, ['avatar_url'])?.toString(),
      _readNested(raw, ['avatar_path'])?.toString(),
    ], fallback: '');

    return ChatUserModel(
      uid: uid.trim(),
      displayName: displayName.trim(),
      username: username.trim().isEmpty
          ? _usernameFromDisplayName(displayName)
          : username.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
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
