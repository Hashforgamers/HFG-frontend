import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  static const primaryCollection = 'chat_rooms';

  final String id;
  final String collection;
  final String type;
  final String name;
  final String imageUrl;
  final List<String> members;
  final List<String> admins;
  final Map<String, String> memberNames;
  final Map<String, String> memberUsernames;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final List<String> typingUserIds;
  final List<String> mutedUserIds;
  final List<String> archivedUserIds;
  final List<String> deletedForUserIds;

  const ChatRoomModel({
    required this.id,
    this.collection = primaryCollection,
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.members,
    required this.admins,
    required this.memberNames,
    this.memberUsernames = const {},
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    required this.typingUserIds,
    required this.mutedUserIds,
    required this.archivedUserIds,
    required this.deletedForUserIds,
  });

  bool get isGroup => type == 'group';
  bool get isDispute =>
      type.toLowerCase() == 'dispute' || id.startsWith('community-dispute-');

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

  factory ChatRoomModel.fromMap(
    Map<String, dynamic> map, {
    String collection = primaryCollection,
  }) {
    final memberNamesRaw = map['member_names'];
    final memberNames = <String, String>{};
    if (memberNamesRaw is Map) {
      for (final entry in memberNamesRaw.entries) {
        memberNames[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }
    final memberUsernames = _stringMap(map['member_usernames']);
    final memberAccounts = map['member_accounts'];
    if (memberAccounts is Map) {
      for (final entry in memberAccounts.entries) {
        final uid = entry.key.toString();
        if (entry.value is! Map) continue;
        final account = Map<String, dynamic>.from(entry.value as Map);
        final name = (account['display_name'] ?? account['name'] ?? '')
            .toString()
            .trim();
        final username =
            (account['username'] ?? account['gameUserName'] ?? '')
                .toString()
                .trim();
        if (name.isNotEmpty) memberNames[uid] = name;
        if (username.isNotEmpty) memberUsernames[uid] = username;
      }
    }
    final rawMembers = map['members'];
    if (rawMembers is List) {
      for (final value in rawMembers.whereType<Map>()) {
        final account = Map<String, dynamic>.from(value);
        final uid = (account['fid'] ??
                account['firebase_uid'] ??
                account['uid'] ??
                account['id'] ??
                '')
            .toString();
        if (uid.isEmpty) continue;
        final name = (account['display_name'] ?? account['name'] ?? '')
            .toString()
            .trim();
        final username =
            (account['username'] ?? account['gameUserName'] ?? '')
                .toString()
                .trim();
        if (name.isNotEmpty) memberNames[uid] = name;
        if (username.isNotEmpty) memberUsernames[uid] = username;
      }
    }

    return ChatRoomModel(
      id: (map['id'] ?? '').toString(),
      collection: collection,
      type: (map['type'] ?? 'direct').toString(),
      name: (map['name'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      members: _memberIds(map['members']),
      admins: _stringList(map['admins']),
      memberNames: memberNames,
      memberUsernames: memberUsernames,
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
      mutedUserIds: _stringList(map['muted_uids']),
      archivedUserIds: _stringList(map['archived_uids']),
      deletedForUserIds: _stringList(map['deleted_for_uids']),
    );
  }

  factory ChatRoomModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String collection = primaryCollection,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return ChatRoomModel.fromMap({
      ...data,
      'id': data['id'] ?? doc.id,
    }, collection: collection);
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static List<String> _memberIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((value) {
          if (value is! Map) return value.toString();
          final member = Map<String, dynamic>.from(value);
          return (member['fid'] ??
                  member['firebase_uid'] ??
                  member['uid'] ??
                  member['id'] ??
                  '')
              .toString();
        })
        .where((value) => value.trim().isNotEmpty)
        .toList();
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return <String, String>{};
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value ?? '').toString()),
    );
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
