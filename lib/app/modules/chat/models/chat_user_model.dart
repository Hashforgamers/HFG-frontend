import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUserModel {
  static const Duration onlineFreshnessWindow = Duration(seconds: 75);
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String phoneNumber;
  final String photoUrl;
  final int? backendUserId;
  final bool isOnline;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  const ChatUserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.photoUrl,
    this.backendUserId,
    required this.isOnline,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  factory ChatUserModel.fromMap(Map<String, dynamic> map) {
    final lastSeenAt = _parseDateTime(map['last_seen_at']);
    final now = DateTime.now();
    final freshEnough = lastSeenAt != null &&
        now.difference(lastSeenAt) <= onlineFreshnessWindow;
    return ChatUserModel(
      uid: (map['uid'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['name'] ?? 'Player').toString(),
      username:
          (map['username'] ?? map['user_name'] ?? map['gameUserName'] ?? '')
              .toString(),
      email: (map['email'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ??
              map['phone'] ??
              map['mobileNo'] ??
              map['mobile_number'] ??
              map['mobile'] ??
              '')
          .toString(),
      photoUrl: (map['photo_url'] ?? '').toString(),
      backendUserId: _parseInt(map['backend_user_id'] ?? map['user_id'] ?? map['id']),
      isOnline: map['is_online'] == true && freshEnough,
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
      lastSeenAt: lastSeenAt,
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
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'backend_user_id': backendUserId,
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}
