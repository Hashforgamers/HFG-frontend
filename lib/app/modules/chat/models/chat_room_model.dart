import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String type;
  final String name;
  final String imageUrl;
  final List<String> members;
  final List<String> admins;
  final Map<String, String> memberNames;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final List<String> typingUserIds;

  const ChatRoomModel({
    required this.id,
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.members,
    required this.admins,
    required this.memberNames,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    required this.typingUserIds,
  });

  bool get isGroup => type == 'group';

  String displayTitleFor(String currentUid) {
    if (isGroup) {
      return name.trim().isEmpty ? 'Group Chat' : name;
    }

    for (final memberId in members) {
      if (memberId == currentUid) continue;
      final other = memberNames[memberId];
      if (other != null && other.trim().isNotEmpty) {
        return other;
      }
      return 'Direct Chat';
    }

    return name.trim().isEmpty ? 'Direct Chat' : name;
  }

  String subtitleFor(String currentUid) {
    if (lastMessage.trim().isEmpty) return 'Start chatting...';
    if (lastMessageSenderId == currentUid) return 'You: $lastMessage';
    return lastMessage;
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    final memberNamesRaw = map['member_names'];
    final memberNames = <String, String>{};
    if (memberNamesRaw is Map) {
      for (final entry in memberNamesRaw.entries) {
        memberNames[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }

    return ChatRoomModel(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? 'direct').toString(),
      name: (map['name'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      members: _stringList(map['members']),
      admins: _stringList(map['admins']),
      memberNames: memberNames,
      lastMessage: (map['last_message'] ?? '').toString(),
      lastMessageSenderId: (map['last_message_sender_id'] ?? '').toString(),
      createdAt:
          _parseDateTime(map['created_at']) ??
          _parseDateTime(map['client_created_at']) ??
          DateTime.now(),
      updatedAt:
          _parseDateTime(map['updated_at']) ??
          _parseDateTime(map['client_updated_at']) ??
          _parseDateTime(map['created_at']) ??
          _parseDateTime(map['client_created_at']) ??
          DateTime.now(),
      lastMessageAt:
          _parseDateTime(map['last_message_at']) ??
          _parseDateTime(map['client_last_message_at']),
      typingUserIds: _stringList(map['typing_uids']),
    );
  }

  factory ChatRoomModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatRoomModel.fromMap({...data, 'id': data['id'] ?? doc.id});
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
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
