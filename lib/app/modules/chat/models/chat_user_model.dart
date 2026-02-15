import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUserModel {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String photoUrl;
  final bool isOnline;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  const ChatUserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.isOnline,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  factory ChatUserModel.fromMap(Map<String, dynamic> map) {
    return ChatUserModel(
      uid: (map['uid'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['name'] ?? 'Player').toString(),
      username:
          (map['username'] ?? map['user_name'] ?? map['gameUserName'] ?? '')
              .toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: (map['photo_url'] ?? '').toString(),
      isOnline: map['is_online'] == true,
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
      lastSeenAt: _parseDateTime(map['last_seen_at']),
    );
  }

  factory ChatUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatUserModel.fromMap({...data, 'uid': data['uid'] ?? doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'username': username,
      'email': email,
      'photo_url': photoUrl,
      'is_online': isOnline,
      'updated_at': Timestamp.fromDate(updatedAt),
      'last_seen_at': lastSeenAt == null
          ? null
          : Timestamp.fromDate(lastSeenAt!),
    };
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
