import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRelationship {
  const FriendRelationship({
    required this.id,
    required this.users,
    required this.requesterUid,
    required this.recipientUid,
    required this.status,
  });

  final String id;
  final List<String> users;
  final String requesterUid;
  final String recipientUid;
  final String status;

  bool isIncoming(String uid) => status == 'pending' && recipientUid == uid;
  bool isOutgoing(String uid) => status == 'pending' && requesterUid == uid;
  String otherUid(String uid) =>
      users.firstWhere((item) => item != uid, orElse: () => '');

  factory FriendRelationship.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FriendRelationship(
      id: doc.id,
      users:
          (data['users'] as List?)?.map((item) => item.toString()).toList() ??
          const [],
      requesterUid: (data['requester_uid'] ?? '').toString(),
      recipientUid: (data['recipient_uid'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
    );
  }
}

class FriendService {
  FriendService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _relationships =>
      _firestore.collection('social_friendships');

  String relationshipId(String first, String second) {
    final users = [first, second]..sort();
    return '${users[0]}_${users[1]}';
  }

  Stream<List<FriendRelationship>> watchRelationships() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const []);
    return _relationships
        .where('users', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FriendRelationship.fromDoc).toList(),
        );
  }

  Future<void> sendRequest(String recipientUid) async {
    final uid = currentUid;
    if (uid == null || uid == recipientUid) return;
    final users = [uid, recipientUid]..sort();
    final ref = _relationships.doc(relationshipId(uid, recipientUid));
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({
      'users': users,
      'requester_uid': uid,
      'recipient_uid': recipientUid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> accept(FriendRelationship relationship) async {
    if (!relationship.isIncoming(currentUid ?? '')) return;
    await _relationships.doc(relationship.id).update({
      'status': 'accepted',
      'accepted_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(FriendRelationship relationship) =>
      _relationships.doc(relationship.id).delete();

  Future<Map<String, dynamic>?> userProfile(String uid) async {
    final doc = await _firestore.collection('chat_users').doc(uid).get();
    if (!doc.exists) return null;
    return {...?doc.data(), 'uid': uid};
  }

  Future<List<Map<String, dynamic>>> allPlayers({int limit = 200}) async {
    final uid = currentUid;
    if (uid == null) return const [];
    final snapshot = await _firestore
        .collection('chat_users')
        .limit(limit)
        .get();
    final blockedSnapshot = await _firestore
        .collection('social_blocks')
        .where('blocker_uid', isEqualTo: uid)
        .get();
    final blocked = blockedSnapshot.docs
        .map((doc) => (doc.data()['blocked_uid'] ?? '').toString())
        .where((value) => value.isNotEmpty)
        .toSet();
    return snapshot.docs
        .where((doc) => doc.id != uid && !blocked.contains(doc.id))
        .map((doc) => {...doc.data(), 'uid': doc.id, 'firebase_uid': doc.id})
        .toList();
  }

  Future<void> blockPlayer(String targetUid) async {
    final uid = currentUid;
    if (uid == null || targetUid.isEmpty || uid == targetUid) return;
    await _firestore.collection('social_blocks').doc('${uid}_$targetUid').set({
      'blocker_uid': uid,
      'blocked_uid': targetUid,
      'created_at': FieldValue.serverTimestamp(),
    });
    final relationship = _relationships.doc(relationshipId(uid, targetUid));
    if ((await relationship.get()).exists) await relationship.delete();
  }

  Future<void> reportPlayer({
    required String targetUid,
    required String reason,
  }) async {
    final uid = currentUid;
    if (uid == null || targetUid.isEmpty || uid == targetUid) return;
    await _firestore.collection('social_reports').add({
      'reporter_uid': uid,
      'target_uid': targetUid,
      'reason': reason,
      'status': 'open',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
