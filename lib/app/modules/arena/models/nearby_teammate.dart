class NearbyTeammate {
  const NearbyTeammate({
    required this.id,
    required this.username,
    required this.avatar,
    required this.latitude,
    required this.longitude,
    required this.games,
    required this.rank,
    required this.languages,
    required this.micEnabled,
    required this.compatibilityScore,
    required this.playStyle,
    required this.online,
  });

  final String id;
  final String username;
  final String avatar;
  final double latitude;
  final double longitude;
  final List<String> games;
  final String rank;
  final List<String> languages;
  final bool micEnabled;
  final double compatibilityScore;
  final String playStyle;
  final bool online;
}
