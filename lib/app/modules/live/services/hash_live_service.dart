import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/live/models/live_stream_model.dart';
import 'package:hash/app/modules/live/models/upcoming_stream_model.dart';
import 'package:hash/core/service/notification_service.dart';

class HashLiveService extends GetxService {
  static const _streams = 'live_streams';
  static const _messages = 'messages';
  static const _viewers = 'viewers';
  static const _hosts = 'live_hosts';
  static const _upcoming = 'upcoming_streams';
  static const _liveAlerts = 'live_alerts';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _streamsRef =>
      _firestore.collection(_streams);
  CollectionReference<Map<String, dynamic>> get _upcomingRef =>
      _firestore.collection(_upcoming);

  String? get currentUid => _auth.currentUser?.uid;
  final Set<String> _announcedUpcoming = <String>{};
  bool _inboxListenerStarted = false;

  Stream<List<LiveStreamModel>> watchLiveStreams() {
    return _streamsRef.snapshots().map((snapshot) {
      final streams =
          snapshot.docs
              .map(LiveStreamModel.fromDoc)
              .where((item) => item.isLive)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return streams;
    });
  }

  Future<String> startOrUpdateLive({
    String? streamId,
    required String title,
    required String game,
    required String youtubeUrl,
    required bool streamingFromCafe,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Please login to go live.');

    final userCtrl = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : null;
    final hostName =
        (userCtrl?.user.value.gameUserName ??
                _auth.currentUser?.displayName ??
                'Host')
            .toString()
            .trim();
    final hostPhoto =
        (userCtrl?.user.value.photoUrl ?? _auth.currentUser?.photoURL ?? '')
            .toString();

    final requestedId = (streamId ?? '').trim();

    final liveByHostSnap = await _streamsRef
        .where('host_uid', isEqualTo: uid)
        .where('is_live', isEqualTo: true)
        .limit(1)
        .get();
    final existingLiveId = liveByHostSnap.docs.isNotEmpty
        ? liveByHostSnap.docs.first.id
        : '';

    if (existingLiveId.isNotEmpty &&
        requestedId.isNotEmpty &&
        requestedId != existingLiveId) {
      throw Exception('You already have an active live stream. End it first.');
    }
    if (existingLiveId.isNotEmpty && requestedId.isEmpty) {
      streamId = existingLiveId;
    }

    final hostRef = _firestore.collection(_hosts).doc(uid);
    final hostSnap = await hostRef.get();
    final hostData = hostSnap.data() ?? <String, dynamic>{};
    final activeStreamId = (hostData['active_stream_id'] ?? '').toString();
    final hostIsLive = hostData['is_live'] == true;

    if (hostIsLive && activeStreamId.isNotEmpty) {
      final activeStreamSnap = await _streamsRef.doc(activeStreamId).get();
      final activeIsLive = activeStreamSnap.data()?['is_live'] == true;
      if (activeIsLive &&
          requestedId.isNotEmpty &&
          requestedId != activeStreamId) {
        throw Exception(
          'You already have an active live stream. End it first.',
        );
      }
      if (activeIsLive && requestedId.isEmpty) {
        streamId = activeStreamId;
      }
    }

    final now = FieldValue.serverTimestamp();
    final doc = (streamId == null || streamId.isEmpty)
        ? _streamsRef.doc()
        : _streamsRef.doc(streamId);

    final payload = {
      'title': title.trim(),
      'game': game.trim(),
      'youtube_url': youtubeUrl.trim(),
      'host_uid': uid,
      'host_name': hostName,
      'host_photo_url': hostPhoto,
      'streaming_from_cafe': streamingFromCafe,
      'is_live': true,
      'viewer_count': 0,
      'created_at': now,
      'updated_at': now,
    };

    await doc.set(payload, SetOptions(merge: true));

    await _firestore.collection(_hosts).doc(uid).set({
      'uid': uid,
      'name': hostName,
      'photo_url': hostPhoto,
      'is_live': true,
      'active_stream_id': doc.id,
      'updated_at': now,
    }, SetOptions(merge: true));

    try {
      await _markUpcomingAsStartedAndNotify(
        hostUid: uid,
        streamId: doc.id,
        title: title.trim(),
        game: game.trim(),
      );
    } catch (_) {
      // Non-blocking side-effect. Stream creation should still succeed even if
      // alert/index logic fails.
    }

    return doc.id;
  }

  Future<void> endLive(String streamId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _streamsRef.doc(streamId).set({
      'is_live': false,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection(_hosts).doc(uid).set({
      'is_live': false,
      'active_stream_id': null,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> resolveCurrentHostActiveStreamId() async {
    final uid = currentUid;
    if (uid == null) return '';

    final hostSnap = await _firestore.collection(_hosts).doc(uid).get();
    final activeFromHost = (hostSnap.data()?['active_stream_id'] ?? '')
        .toString()
        .trim();
    if (activeFromHost.isNotEmpty) return activeFromHost;

    final liveByHostSnap = await _streamsRef
        .where('host_uid', isEqualTo: uid)
        .where('is_live', isEqualTo: true)
        .limit(1)
        .get();
    if (liveByHostSnap.docs.isNotEmpty) {
      return liveByHostSnap.docs.first.id;
    }
    return '';
  }

  Stream<LiveStreamModel?> watchStream(String streamId) {
    return _streamsRef.doc(streamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LiveStreamModel.fromDoc(doc);
    });
  }

  Stream<int> watchViewerCount(String streamId) {
    return _streamsRef.doc(streamId).snapshots().map((doc) {
      final data = doc.data();
      return (data?['viewer_count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> joinLiveStream(String streamId) async {
    final uid = currentUid;
    if (uid == null) return;
    final viewerDoc = _streamsRef.doc(streamId).collection(_viewers).doc(uid);
    final exists = await viewerDoc.get();
    if (!exists.exists) {
      await viewerDoc.set({'joined_at': FieldValue.serverTimestamp()});
      await _streamsRef.doc(streamId).set({
        'viewer_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> leaveLiveStream(String streamId) async {
    final uid = currentUid;
    if (uid == null) return;
    final viewerDoc = _streamsRef.doc(streamId).collection(_viewers).doc(uid);
    final exists = await viewerDoc.get();
    if (!exists.exists) return;
    await viewerDoc.delete();
    await _firestore.runTransaction((txn) async {
      final streamRef = _streamsRef.doc(streamId);
      final streamSnap = await txn.get(streamRef);
      final current =
          (streamSnap.data()?['viewer_count'] as num?)?.toInt() ?? 0;
      txn.set(streamRef, {
        'viewer_count': current > 0 ? current - 1 : 0,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String streamId) {
    return _streamsRef
        .doc(streamId)
        .collection(_messages)
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {...(d.data()), 'id': d.id}).toList());
  }

  Future<void> sendMessage(String streamId, String text) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Please login to chat.');
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    final userCtrl = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : null;
    final senderName =
        (userCtrl?.user.value.gameUserName ??
                _auth.currentUser?.displayName ??
                'Player')
            .toString();

    await _streamsRef.doc(streamId).collection(_messages).add({
      'sender_uid': uid,
      'sender_name': senderName,
      'text': cleaned,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isFollowingHost(String hostUid) async {
    final uid = currentUid;
    if (uid == null || hostUid.isEmpty) return false;
    final doc = await _firestore
        .collection(_hosts)
        .doc(hostUid)
        .collection('followers')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<bool> toggleFollowHost(String hostUid) async {
    final uid = currentUid;
    if (uid == null || hostUid.isEmpty || uid == hostUid) return false;

    final hostDoc = _firestore.collection(_hosts).doc(hostUid);
    final followerDoc = hostDoc.collection('followers').doc(uid);
    final snap = await followerDoc.get();

    if (snap.exists) {
      await followerDoc.delete();
      await hostDoc.set({
        'followers_count': FieldValue.increment(-1),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return false;
    }

    await followerDoc.set({'followed_at': FieldValue.serverTimestamp()});
    await hostDoc.set({
      'followers_count': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  Stream<Map<String, dynamic>?> watchHostProfile(String hostUid) {
    return _firestore.collection(_hosts).doc(hostUid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  Stream<int> watchHostFollowersCount(String hostUid) {
    return _firestore.collection(_hosts).doc(hostUid).snapshots().map((doc) {
      final data = doc.data();
      return (data?['followers_count'] as num?)?.toInt() ?? 0;
    });
  }

  Stream<List<Map<String, dynamic>>> watchHostFollowers(String hostUid) {
    return _firestore
        .collection(_hosts)
        .doc(hostUid)
        .collection('followers')
        .orderBy('followed_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];

          final users = await Future.wait(
            snapshot.docs.map((doc) async {
              final uid = doc.id;
              final chatUser = await _firestore
                  .collection('chat_users')
                  .doc(uid)
                  .get();
              final chatData = chatUser.data() ?? <String, dynamic>{};

              if (chatData.isEmpty) {
                final hostDoc = await _firestore
                    .collection(_hosts)
                    .doc(uid)
                    .get();
                final hostData = hostDoc.data() ?? <String, dynamic>{};
                return <String, dynamic>{
                  'uid': uid,
                  'name': (hostData['name'] ?? 'Player').toString(),
                  'username': '',
                  'photo_url': (hostData['photo_url'] ?? '').toString(),
                };
              }

              return <String, dynamic>{
                'uid': uid,
                'name':
                    (chatData['display_name'] ?? chatData['name'] ?? 'Player')
                        .toString(),
                'username': (chatData['username'] ?? '').toString(),
                'photo_url': (chatData['photo_url'] ?? '').toString(),
              };
            }),
          );

          return users;
        });
  }

  Stream<int> watchHostTotalStreams(String hostUid) {
    return _streamsRef
        .where('host_uid', isEqualTo: hostUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<LiveStreamModel>> watchHostStreams(String hostUid) {
    return _streamsRef.where('host_uid', isEqualTo: hostUid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(LiveStreamModel.fromDoc).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Stream<List<UpcomingStreamModel>> watchUpcomingStreams() {
    return _upcomingRef
        .where('start_at', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('start_at', descending: false)
        .limit(40)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(UpcomingStreamModel.fromDoc).toList(),
        );
  }

  Future<String> scheduleUpcomingStream({
    required String title,
    required String game,
    required DateTime startAt,
    required bool streamingFromCafe,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Please login to schedule stream.');

    final userCtrl = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : null;
    final hostName =
        (userCtrl?.user.value.gameUserName ??
                _auth.currentUser?.displayName ??
                'Host')
            .toString()
            .trim();
    final hostPhoto =
        (userCtrl?.user.value.photoUrl ?? _auth.currentUser?.photoURL ?? '')
            .toString();

    final doc = _upcomingRef.doc();
    await doc.set({
      'title': title.trim(),
      'game': game.trim(),
      'host_uid': uid,
      'host_name': hostName,
      'host_photo_url': hostPhoto,
      'start_at': Timestamp.fromDate(startAt),
      'streaming_from_cafe': streamingFromCafe,
      'joined_user_ids': <String>[uid],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> toggleUpcomingJoin({
    required String upcomingId,
    required bool join,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Please login to set reminder.');
    await _upcomingRef.doc(upcomingId).set({
      'joined_user_ids': join
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUpcomingStream({
    required String upcomingId,
    required String title,
    required String game,
    required DateTime startAt,
    required bool streamingFromCafe,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Please login to update stream.');

    final doc = await _upcomingRef.doc(upcomingId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('Scheduled stream not found.');
    }
    if ((data['host_uid'] ?? '').toString() != uid) {
      throw Exception('Only host can edit this stream.');
    }
    if (data['is_started'] == true) {
      throw Exception('Started stream cannot be edited.');
    }

    await _upcomingRef.doc(upcomingId).set({
      'title': title.trim(),
      'game': game.trim(),
      'start_at': Timestamp.fromDate(startAt),
      'streaming_from_cafe': streamingFromCafe,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool isJoinedUpcoming(UpcomingStreamModel item) {
    final uid = currentUid;
    if (uid == null) return false;
    return item.joinedUserIds.contains(uid);
  }

  void startUpcomingStartAlerts() {
    final uid = currentUid;
    if (uid == null) return;
    watchUpcomingStreams().listen((items) async {
      final notification = Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : null;
      if (notification == null) return;

      final now = DateTime.now();
      for (final item in items) {
        if (!item.joinedUserIds.contains(uid)) continue;
        final diff = item.startAt.difference(now).inMinutes;
        final shouldAlert = diff <= 1 && diff >= -3;
        if (!shouldAlert) continue;
        if (_announcedUpcoming.contains(item.id)) continue;
        _announcedUpcoming.add(item.id);
        await notification.showLiveNotification(
          title: 'Stream starting now',
          body: '${item.title} by ${item.hostName} is live now.',
          payload: '',
        );
      }
    });
  }

  void startLiveAlertInboxListener() {
    if (_inboxListenerStarted) return;
    final uid = currentUid;
    if (uid == null) return;
    _inboxListenerStarted = true;

    _firestore
        .collection(_liveAlerts)
        .where('target_uid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
          final notification = Get.isRegistered<NotificationController>()
              ? Get.find<NotificationController>()
              : null;
          if (notification == null) return;

          final docs =
              snapshot.docs.where((doc) => doc.data()['seen'] != true).toList()
                ..sort((a, b) {
                  final aTs = a.data()['created_at'];
                  final bTs = b.data()['created_at'];
                  final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                  final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                  return bMs.compareTo(aMs);
                });

          for (final doc in docs) {
            final data = doc.data();
            final title = (data['title'] ?? 'Live Now').toString();
            final body = (data['body'] ?? 'A stream you joined is live.')
                .toString();
            await notification.showLiveNotification(
              title: title,
              body: body,
              payload: (data['stream_id'] ?? '').toString().isNotEmpty
                  ? 'live:${data['stream_id']}'
                  : '',
            );
            await doc.reference.set({
              'seen': true,
              'seen_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });
  }

  Future<void> _markUpcomingAsStartedAndNotify({
    required String hostUid,
    required String streamId,
    required String title,
    required String game,
  }) async {
    final upcomingSnap = await _upcomingRef
        .where('host_uid', isEqualTo: hostUid)
        .where('is_started', isEqualTo: false)
        .where(
          'start_at',
          isLessThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 6)),
          ),
        )
        .limit(20)
        .get();

    if (upcomingSnap.docs.isEmpty) return;

    for (final doc in upcomingSnap.docs) {
      final data = doc.data();
      final upcomingTitle = (data['title'] ?? '').toString().toLowerCase();
      final upcomingGame = (data['game'] ?? '').toString().toLowerCase();
      final titleMatch = upcomingTitle == title.toLowerCase();
      final gameMatch = upcomingGame == game.toLowerCase();
      if (!titleMatch && !gameMatch) continue;

      final joined = ((data['joined_user_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toSet();

      await doc.reference.set({
        'is_started': true,
        'started_stream_id': streamId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final batch = _firestore.batch();
      for (final uid in joined) {
        if (uid == hostUid) continue;
        final alertRef = _firestore.collection(_liveAlerts).doc();
        batch.set(alertRef, {
          'target_uid': uid,
          'stream_id': streamId,
          'upcoming_id': doc.id,
          'title': 'Stream is live now',
          'body':
              '${data['title'] ?? 'A stream'} by ${data['host_name'] ?? 'Host'} just started.',
          'seen': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
