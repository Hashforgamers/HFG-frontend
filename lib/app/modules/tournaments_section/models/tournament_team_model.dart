class TournamentTeamModel {
  final String id;
  final String name;
  final String rank;
  final String points;
  final String matchesWon;
  final String photoUrl;

  const TournamentTeamModel({
    required this.id,
    required this.name,
    required this.rank,
    required this.points,
    required this.matchesWon,
    required this.photoUrl,
  });

  factory TournamentTeamModel.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final inferredRank =
        json['rank'] ??
        json['position'] ??
        json['seed'] ??
        json['leaderboard_rank'] ??
        (index + 1);
    final inferredPoints =
        json['points'] ??
        json['score'] ??
        json['total_points'] ??
        json['elo'] ??
        0;
    final inferredMatchesWon =
        json['matchesWon'] ?? json['matches_won'] ?? json['wins'] ?? 0;

    return TournamentTeamModel(
      id: (json['id'] ?? json['team_id'] ?? '').toString(),
      name: (json['name'] ?? json['team_name'] ?? 'Unknown Team').toString(),
      rank: inferredRank.toString(),
      points: inferredPoints.toString(),
      matchesWon: inferredMatchesWon.toString(),
      photoUrl:
          (json['photoUrl'] ??
                  json['avatar'] ??
                  json['logo'] ??
                  'assets/hash_store_images/team_fallback.png')
              .toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rank': rank,
      'points': points,
      'matchesWon': matchesWon,
      'photoUrl': photoUrl,
    };
  }
}
