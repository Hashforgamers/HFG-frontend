import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamModel {
  final String id;
  final String title;
  final String game;
  final String youtubeUrl;
  final String hostUid;
  final String hostName;
  final String hostPhotoUrl;
  final bool streamingFromCafe;
  final bool isLive;
  final int viewerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LiveStreamModel({
    required this.id,
    required this.title,
    required this.game,
    required this.youtubeUrl,
    required this.hostUid,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.streamingFromCafe,
    required this.isLive,
    required this.viewerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveStreamModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return LiveStreamModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      game: (data['game'] ?? '').toString(),
      youtubeUrl: (data['youtube_url'] ?? '').toString(),
      hostUid: (data['host_uid'] ?? '').toString(),
      hostName: (data['host_name'] ?? 'Host').toString(),
      hostPhotoUrl: (data['host_photo_url'] ?? '').toString(),
      streamingFromCafe: data['streaming_from_cafe'] == true,
      isLive: data['is_live'] == true,
      viewerCount: (data['viewer_count'] as num?)?.toInt() ?? 0,
      createdAt: parseTs(data['created_at']),
      updatedAt: parseTs(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'game': game,
      'youtube_url': youtubeUrl,
      'host_uid': hostUid,
      'host_name': hostName,
      'host_photo_url': hostPhotoUrl,
      'streaming_from_cafe': streamingFromCafe,
      'is_live': isLive,
      'viewer_count': viewerCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
