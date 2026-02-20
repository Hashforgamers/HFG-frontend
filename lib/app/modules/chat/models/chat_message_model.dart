import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final DateTime createdAt;
  final List<String> seenBy;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.createdAt,
    required this.seenBy,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: (map['id'] ?? '').toString(),
      roomId: (map['room_id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      senderName: (map['sender_name'] ?? 'Player').toString(),
      text: (map['text'] ?? '').toString(),
      type: (map['type'] ?? 'text').toString(),
      createdAt:
          _parseDateTime(map['created_at']) ??
          _parseDateTime(map['client_created_at']) ??
          DateTime.now(),
      seenBy: _stringList(map['seen_by']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatMessageModel.fromMap({...data, 'id': data['id'] ?? doc.id});
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
