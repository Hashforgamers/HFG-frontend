import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingStreamModel {
  final String id;
  final String title;
  final String game;
  final String hostUid;
  final String hostName;
  final String hostPhotoUrl;
  final DateTime startAt;
  final bool streamingFromCafe;
  final List<String> joinedUserIds;

  const UpcomingStreamModel({
    required this.id,
    required this.title,
    required this.game,
    required this.hostUid,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.startAt,
    required this.streamingFromCafe,
    required this.joinedUserIds,
  });

  factory UpcomingStreamModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parse(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UpcomingStreamModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      game: (data['game'] ?? '').toString(),
      hostUid: (data['host_uid'] ?? '').toString(),
      hostName: (data['host_name'] ?? 'Host').toString(),
      hostPhotoUrl: (data['host_photo_url'] ?? '').toString(),
      startAt: parse(data['start_at']),
      streamingFromCafe: data['streaming_from_cafe'] == true,
      joinedUserIds: ((data['joined_user_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
