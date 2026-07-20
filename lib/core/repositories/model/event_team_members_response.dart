class EventTeamMembersResponse {
  const EventTeamMembersResponse({
    required this.eventId,
    required this.tournament,
    required this.members,
  });

  final String eventId;
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> members;

  String get tournamentSource =>
      (tournament['source'] ?? '').toString().trim().toLowerCase();

  bool get isCommunity => tournamentSource == 'community';
}
