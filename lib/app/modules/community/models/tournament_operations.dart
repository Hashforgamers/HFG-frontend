class CommunityTeamMember {
  final int? userId;
  final String displayName;
  final String gameId;
  final String role;
  final String invitationStatus;

  const CommunityTeamMember({
    required this.userId,
    required this.displayName,
    required this.gameId,
    required this.role,
    required this.invitationStatus,
  });

  factory CommunityTeamMember.fromJson(Map<String, dynamic> json) {
    final gamer = _map(json['gamer'] ?? json['user']);
    return CommunityTeamMember(
      userId: _int(json['user_id'] ?? gamer['id']),
      displayName:
          (json['display_name'] ??
                  gamer['display_name'] ??
                  gamer['name'] ??
                  'Player')
              .toString(),
      gameId: (json['game_id'] ?? json['game_username'] ?? '').toString(),
      role: (json['role'] ?? 'player').toString(),
      invitationStatus:
          (json['invitation_status'] ?? json['status'] ?? 'pending').toString(),
    );
  }
}

class CommunityTeam {
  final String id;
  final String tournamentId;
  final String name;
  final String status;
  final int? seed;
  final bool checkedIn;
  final bool rosterLocked;
  final String? rejectionReason;
  final List<CommunityTeamMember> members;

  const CommunityTeam({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.status,
    required this.seed,
    required this.checkedIn,
    required this.rosterLocked,
    required this.rejectionReason,
    required this.members,
  });

  int get acceptedMembers => members
      .where(
        (member) =>
            member.role == 'captain' ||
            {'accepted', 'active'}.contains(member.invitationStatus),
      )
      .length;

  factory CommunityTeam.fromJson(Map<String, dynamic> json) => CommunityTeam(
    id: (json['id'] ?? '').toString(),
    tournamentId: (json['tournament_id'] ?? '').toString(),
    name: (json['name'] ?? json['team_name'] ?? 'Team').toString(),
    status: (json['status'] ?? 'pending').toString(),
    seed: _int(json['seed']),
    checkedIn: json['checked_in'] == true || json['checked_in_at'] != null,
    rosterLocked:
        json['roster_locked'] == true || json['roster_locked_at'] != null,
    rejectionReason: (json['rejection_reason'] ?? json['information_request'])
        ?.toString(),
    members: _list(
      json['members'] ?? json['roster'],
    ).map(CommunityTeamMember.fromJson).toList(),
  );
}

class CommunityMatch {
  final String id;
  final String tournamentId;
  final int? round;
  final String? roundName;
  final String status;
  final DateTime? scheduledAt;
  final CommunityTeam? teamA;
  final CommunityTeam? teamB;
  final String? winnerTeamId;
  final int? teamAScore;
  final int? teamBScore;
  final String? lobbyId;
  final String? accessCode;

  const CommunityMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.roundName,
    required this.status,
    required this.scheduledAt,
    required this.teamA,
    required this.teamB,
    required this.winnerTeamId,
    required this.teamAScore,
    required this.teamBScore,
    required this.lobbyId,
    required this.accessCode,
  });

  factory CommunityMatch.fromJson(Map<String, dynamic> json) => CommunityMatch(
    id: (json['id'] ?? '').toString(),
    tournamentId: (json['tournament_id'] ?? '').toString(),
    round: _int(json['round'] ?? json['round_number']),
    roundName: (json['round_name'] ?? json['stage'])?.toString(),
    status: (json['status'] ?? 'scheduled').toString(),
    scheduledAt: _date(json['scheduled_at'] ?? json['start_at']),
    teamA: json['team_a'] is Map
        ? CommunityTeam.fromJson(_map(json['team_a']))
        : null,
    teamB: json['team_b'] is Map
        ? CommunityTeam.fromJson(_map(json['team_b']))
        : null,
    winnerTeamId: json['winner_team_id']?.toString(),
    teamAScore: _int(json['team_a_score'] ?? json['score_a']),
    teamBScore: _int(json['team_b_score'] ?? json['score_b']),
    lobbyId: (json['lobby_id'] ?? _map(json['lobby'])['lobby_id'])?.toString(),
    accessCode: (json['access_code'] ?? _map(json['lobby'])['access_code'])
        ?.toString(),
  );
}

class TournamentReadiness {
  final bool readyToPublish;
  final List<String> blockers;
  final List<String> warnings;

  const TournamentReadiness({
    required this.readyToPublish,
    required this.blockers,
    required this.warnings,
  });

  factory TournamentReadiness.fromJson(Map<String, dynamic> json) =>
      TournamentReadiness(
        readyToPublish: json['ready_to_publish'] == true,
        blockers: _strings(json['blockers'] ?? json['hard_blockers']),
        warnings: _strings(json['warnings'] ?? json['operational_warnings']),
      );
}

class TournamentLeaderboardEntry {
  final int? rank;
  final String teamId;
  final String name;
  final num points;
  final int kills;
  final int penalties;

  const TournamentLeaderboardEntry({
    required this.rank,
    required this.teamId,
    required this.name,
    required this.points,
    required this.kills,
    required this.penalties,
  });

  factory TournamentLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final team = _map(json['team']);
    return TournamentLeaderboardEntry(
      rank: _int(json['rank'] ?? json['position']),
      teamId: (json['team_id'] ?? team['id'] ?? '').toString(),
      name: (json['team_name'] ?? team['name'] ?? 'Team').toString(),
      points: (json['points'] as num?) ?? 0,
      kills: _int(json['kills']) ?? 0,
      penalties: _int(json['penalty_points'] ?? json['penalties']) ?? 0,
    );
  }
}

class OrganizerProfile {
  final int? hostUserId;
  final bool verified;
  final double rating;
  final int reviewCount;
  final int hostedCount;
  final int completedCount;
  final int cancelledCount;

  const OrganizerProfile({
    required this.hostUserId,
    required this.verified,
    required this.rating,
    required this.reviewCount,
    required this.hostedCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  factory OrganizerProfile.fromJson(Map<String, dynamic> json) =>
      OrganizerProfile(
        hostUserId: _int(json['host_user_id'] ?? json['user_id'] ?? json['id']),
        verified:
            json['verified'] == true ||
            json['verification_status'] == 'verified',
        rating:
            (json['participant_rating'] as num?)?.toDouble() ??
            (json['average_rating'] as num?)?.toDouble() ??
            0,
        reviewCount: _int(json['review_count']) ?? 0,
        hostedCount: _int(json['hosted_count']) ?? 0,
        completedCount: _int(json['completed_count']) ?? 0,
        cancelledCount: _int(json['cancelled_count']) ?? 0,
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is Map) {
    value =
        value['items'] ?? value['data'] ?? value['matches'] ?? value['teams'];
  }
  return value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];
}

List<String> _strings(dynamic value) => value is List
    ? value
          .map(
            (item) => item is Map
                ? (item['message'] ?? item['code'] ?? item).toString()
                : item.toString(),
          )
          .toList()
    : const [];

int? _int(dynamic value) => value is num
    ? value.toInt()
    : value == null
    ? null
    : int.tryParse(value.toString());

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

List<CommunityTeam> parseCommunityTeams(dynamic value) =>
    _list(value).map(CommunityTeam.fromJson).toList();

List<CommunityMatch> parseCommunityMatches(dynamic value) =>
    _list(value).map(CommunityMatch.fromJson).toList();

List<TournamentLeaderboardEntry> parseTournamentLeaderboard(dynamic value) =>
    _list(value).map(TournamentLeaderboardEntry.fromJson).toList();
