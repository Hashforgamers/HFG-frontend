import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LfgPost {
  const LfgPost({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.game,
    required this.mode,
    required this.micOn,
    required this.note,
    required this.expiresAt,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String game;
  final String mode;
  final bool micOn;
  final String note;
  final DateTime expiresAt;

  factory LfgPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LfgPost(
      uid: doc.id,
      displayName: (data['display_name'] ?? data['username'] ?? 'HASH player')
          .toString(),
      photoUrl: (data['photo_url'] ?? '').toString(),
      game: (data['game'] ?? 'Any game').toString(),
      mode: (data['mode'] ?? 'Chill').toString(),
      micOn: data['mic_on'] == true,
      note: (data['note'] ?? '').toString(),
      expiresAt:
          (data['expires_at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LfgLobbyMessage {
  const LfgLobbyMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.type,
    required this.text,
    required this.audioUrl,
    required this.durationMs,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String type;
  final String text;
  final String audioUrl;
  final int durationMs;
  final DateTime createdAt;

  factory LfgLobbyMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LfgLobbyMessage(
      id: doc.id,
      senderId: (data['sender_id'] ?? '').toString(),
      senderName: (data['sender_name'] ?? 'HASH player').toString(),
      senderPhotoUrl: (data['sender_photo_url'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      text: (data['text'] ?? '').toString(),
      audioUrl: (data['audio_url'] ?? '').toString(),
      durationMs: (data['duration_ms'] as num?)?.toInt() ?? 0,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.tryParse((data['client_created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class LfgService {
  LfgService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('social_lfg_posts');

  Stream<List<LfgLobbyMessage>> watchLobbyMessages(String lobbyId) {
    return _posts
        .doc(lobbyId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(LfgLobbyMessage.fromDoc)
              .toList(growable: false),
        );
  }

  Future<Map<String, dynamic>> _currentProfile() async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to squad up.');
    final profile = await _firestore.collection('chat_users').doc(uid).get();
    return profile.data() ?? const <String, dynamic>{};
  }

  Future<void> joinLobby(String lobbyId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to join the lobby.');
    final lobbyRef = _posts.doc(lobbyId);
    await _firestore.runTransaction((transaction) async {
      final lobby = await transaction.get(lobbyRef);
      final rawMembers = lobby.data()?['member_ids'];
      final members = rawMembers is List
          ? rawMembers.map((value) => value.toString()).toList()
          : <String>[];
      if (!members.contains(uid)) members.add(uid);
      transaction.set(lobbyRef, {
        'member_ids': members,
        'member_count': members.length,
        'last_activity_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> sendText({required String lobbyId, required String text}) async {
    final uid = currentUid;
    final trimmed = text.trim();
    if (uid == null) throw StateError('Sign in to send messages.');
    if (trimmed.isEmpty) return;
    final profile = await _currentProfile();
    final message = _posts.doc(lobbyId).collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(message, {
      'sender_id': uid,
      'sender_name':
          profile['display_name'] ??
          profile['username'] ??
          _auth.currentUser?.displayName ??
          'HASH player',
      'sender_photo_url':
          profile['photo_url'] ?? _auth.currentUser?.photoURL ?? '',
      'type': 'text',
      'text': trimmed,
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().toIso8601String(),
    });
    batch.set(_posts.doc(lobbyId), {
      'last_message': trimmed,
      'last_activity_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> sendVoice({
    required String lobbyId,
    required String audioUrl,
    required int durationMs,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to send voice notes.');
    final profile = await _currentProfile();
    final message = _posts.doc(lobbyId).collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(message, {
      'sender_id': uid,
      'sender_name':
          profile['display_name'] ??
          profile['username'] ??
          _auth.currentUser?.displayName ??
          'HASH player',
      'sender_photo_url':
          profile['photo_url'] ?? _auth.currentUser?.photoURL ?? '',
      'type': 'voice',
      'text': '',
      'audio_url': audioUrl,
      'duration_ms': durationMs,
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().toIso8601String(),
    });
    batch.set(_posts.doc(lobbyId), {
      'last_message': 'Voice drop',
      'last_activity_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<LfgPost>> watchActive() {
    return _posts.where('is_active', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final now = DateTime.now();
      final posts =
          snapshot.docs
              .map(LfgPost.fromDoc)
              .where((post) => post.expiresAt.isAfter(now))
              .toList()
            ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      return posts;
    });
  }

  Future<void> publish({
    required String game,
    required String mode,
    required bool micOn,
    required String note,
    Duration duration = const Duration(hours: 2),
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to squad up.');
    final profile = await _firestore.collection('chat_users').doc(uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    await _posts.doc(uid).set({
      'uid': uid,
      'display_name':
          data['display_name'] ??
          data['username'] ??
          _auth.currentUser?.displayName ??
          'HASH player',
      'photo_url': data['photo_url'] ?? _auth.currentUser?.photoURL ?? '',
      'game': game,
      'mode': mode,
      'mic_on': micOn,
      'note': note.trim(),
      'is_active': true,
      'owner_id': uid,
      'member_ids': FieldValue.arrayUnion([uid]),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'expires_at': Timestamp.fromDate(DateTime.now().add(duration)),
    }, SetOptions(merge: true));
  }

  Future<void> close() async {
    final uid = currentUid;
    if (uid == null) return;
    await _posts.doc(uid).set({
      'is_active': false,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
