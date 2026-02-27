import 'package:hash/app/modules/tournaments_section/models/tournament_team_model.dart';

enum TournamentStatus { upcoming, live, completed, unknown }

class TournamentModel {
  final String id;
  final String title;
  final String imageUrl;
  final String banner;
  final DateTime? startDate;
  final DateTime? endDate;
  final TournamentStatus status;
  final String entryFee;
  final String prizePool;
  final String players;
  final String teamMode;
  final String timeLeft;
  final String description;
  final String hostedBy;
  final String rules;
  final String technical;
  final List<TournamentTeamModel> teams;
  final bool? _isJoined;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.banner,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.entryFee,
    required this.prizePool,
    required this.players,
    required this.teamMode,
    required this.timeLeft,
    required this.description,
    required this.hostedBy,
    required this.rules,
    required this.technical,
    required this.teams,
    bool? isJoined = false,
  }) : _isJoined = isJoined;

  bool get isJoined => _isJoined ?? false;

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    final teamsPayload = _extractList(
      json['teams'] ?? json['participants'] ?? json['leaderboard'],
    );
    final teams = teamsPayload
        .asMap()
        .entries
        .map(
          (entry) => TournamentTeamModel.fromJson(
            Map<String, dynamic>.from(entry.value),
            index: entry.key,
          ),
        )
        .toList();

    final entryFee =
        json['entryFee'] ??
        json['entry_fee'] ??
        json['registration_fee'] ??
        json['fee'] ??
        '0';
    final currency = (json['currency'] ?? 'INR').toString();
    final maxPlayers = _toInt(json['max_players'] ?? json['maxPlayers']);
    final currentPlayers = _toInt(
      json['players_count'] ?? json['current_players'] ?? json['playersCount'],
    );

    return TournamentModel(
      id: (json['id'] ?? json['event_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Tournament').toString(),
      imageUrl:
          (json['imageUrl'] ??
                  json['image_url'] ??
                  json['banner_image_url'] ??
                  json['thumbnail'] ??
                  'assets/hash_store_images/tournament_img1.png')
              .toString(),
      banner:
          (json['banner'] ??
                  json['banner_image_url'] ??
                  json['banner_url'] ??
                  json['cover_image'] ??
                  json['imageUrl'] ??
                  json['image_url'] ??
                  'assets/hash_store_images/tournament_banner.png')
              .toString(),
      startDate: _parseDate(
        json['startDate'] ?? json['start_date'] ?? json['start_at'],
      ),
      endDate: _parseDate(json['endDate'] ?? json['end_date'] ?? json['end_at']),
      status: _parseStatus(json['status'] ?? json['flag']),
      entryFee: _formatEntryFee(entryFee, currency),
      prizePool: (json['prizePool'] ?? json['prize_pool'] ?? '-').toString(),
      players: maxPlayers != null
          ? '${currentPlayers ?? 0}/$maxPlayers'
          : (json['players'] ?? '-').toString(),
      teamMode:
          (json['teamMode'] ??
                  json['team_mode'] ??
                  (json['is_individual'] == true ? 'Solo' : 'Team'))
              .toString(),
      timeLeft: (json['timeLeft'] ?? json['time_left'] ?? '').toString(),
      description:
          (json['description'] ?? 'Tournament details will be updated soon.')
              .toString(),
      hostedBy: (json['hostedBy'] ?? json['hosted_by'] ?? 'HashForGamers')
          .toString(),
      rules: (json['rules'] ?? 'Rules will be announced soon.').toString(),
      technical: (json['technical'] ?? 'Technical details coming soon.')
          .toString(),
      teams: teams,
      isJoined: _toBool(json['is_joined']),
    );
  }

  TournamentModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? banner,
    DateTime? startDate,
    DateTime? endDate,
    TournamentStatus? status,
    String? entryFee,
    String? prizePool,
    String? players,
    String? teamMode,
    String? timeLeft,
    String? description,
    String? hostedBy,
    String? rules,
    String? technical,
    List<TournamentTeamModel>? teams,
    bool? isJoined,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      banner: banner ?? this.banner,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      players: players ?? this.players,
      teamMode: teamMode ?? this.teamMode,
      timeLeft: timeLeft ?? this.timeLeft,
      description: description ?? this.description,
      hostedBy: hostedBy ?? this.hostedBy,
      rules: rules ?? this.rules,
      technical: technical ?? this.technical,
      teams: teams ?? this.teams,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  String get statusLabel {
    switch (status) {
      case TournamentStatus.upcoming:
        return 'upcoming';
      case TournamentStatus.live:
        return 'live';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.unknown:
        return 'unknown';
    }
  }

  bool matchesFilter(String category) {
    if (category == 'All') return true;
    return statusLabel == category.toLowerCase();
  }

  static TournamentStatus _parseStatus(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? '';
    if (raw.contains('upcoming')) return TournamentStatus.upcoming;
    if (raw.contains('live') || raw.contains('ongoing')) {
      return TournamentStatus.live;
    }
    if (raw.contains('completed') || raw.contains('finished')) {
      return TournamentStatus.completed;
    }
    return TournamentStatus.unknown;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static String _formatEntryFee(dynamic fee, String currency) {
    final amount = num.tryParse(fee.toString()) ?? 0;
    if (amount == 0) return 'Free';
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    if (amount % 1 == 0) {
      return '$symbol${amount.toInt()}';
    }
    return '$symbol$amount';
  }
}
