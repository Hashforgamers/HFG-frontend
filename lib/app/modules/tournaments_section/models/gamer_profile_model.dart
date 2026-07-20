class GamerProfileModel {
  const GamerProfileModel({
    required this.id,
    required this.displayName,
    required this.gameUsername,
    required this.avatarUrl,
    required this.memberSince,
    required this.stats,
    required this.host,
  });

  final int id;
  final String displayName;
  final String gameUsername;
  final String avatarUrl;
  final DateTime? memberSince;
  final GamerTournamentStats stats;
  final GamerHostProfile host;

  factory GamerProfileModel.fromJson(Map<String, dynamic> json) {
    return GamerProfileModel(
      id: _integer(json['id']),
      displayName: (json['display_name'] ?? 'Gamer').toString(),
      gameUsername: (json['game_username'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      memberSince: DateTime.tryParse((json['member_since'] ?? '').toString()),
      stats: GamerTournamentStats.fromJson(_map(json['tournament_stats'])),
      host: GamerHostProfile.fromJson(_map(json['host'])),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
  static int _integer(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class GamerTournamentStats {
  const GamerTournamentStats({
    required this.joined,
    required this.hosted,
    required this.completed,
    required this.wins,
    required this.podiumFinishes,
  });
  final int joined;
  final int hosted;
  final int completed;
  final int wins;
  final int podiumFinishes;

  factory GamerTournamentStats.fromJson(Map<String, dynamic> json) =>
      GamerTournamentStats(
        joined: _int(json['tournaments_joined']),
        hosted: _int(json['tournaments_hosted']),
        completed: _int(json['tournaments_completed']),
        wins: _int(json['wins']),
        podiumFinishes: _int(json['podium_finishes']),
      );
  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class GamerHostProfile {
  const GamerHostProfile({
    required this.isVerified,
    required this.tier,
    this.averageRating,
    this.completionRate,
    this.onTimePayoutRate,
  });
  final bool isVerified;
  final String tier;
  final double? averageRating;
  final double? completionRate;
  final double? onTimePayoutRate;

  factory GamerHostProfile.fromJson(Map<String, dynamic> json) =>
      GamerHostProfile(
        isVerified: json['is_verified'] == true,
        tier: (json['tier'] ?? '').toString(),
        averageRating: _double(json['average_rating']),
        completionRate: _double(json['completion_rate']),
        onTimePayoutRate: _double(json['on_time_payout_rate']),
      );
  static double? _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
}
