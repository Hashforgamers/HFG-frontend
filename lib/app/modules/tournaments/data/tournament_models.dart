// Models for the community tournament API (`/api/v1/community`).
//
// Field names follow the backend serializer maps in the tournament API
// handoff. Parsing is defensive: missing keys fall back to neutral values and
// unknown keys are ignored, because several endpoints add wrapper fields.

Map<String, dynamic> jsonMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> jsonList(dynamic v) {
  if (v is Map) v = v['items'] ?? v['data'] ?? v['results'];
  return v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
}

int? jsonInt(dynamic v) =>
    v is num ? v.toInt() : (v == null ? null : int.tryParse(v.toString()));

double jsonDouble(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

String? jsonStr(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? null : s;
}

DateTime? jsonDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<String> jsonStrings(dynamic v) => v is List
    ? v
          .map(
            (e) => e is Map
                ? (e['message'] ?? e['detail'] ?? e['code'] ?? '').toString()
                : e.toString(),
          )
          .where((e) => e.trim().isNotEmpty)
          .toList()
    : const [];

class Paginated<T> {
  final List<T> items;
  final int page;
  final int pages;
  final int total;
  const Paginated(this.items, {this.page = 1, this.pages = 1, this.total = 0});

  bool get hasMore => page < pages;

  factory Paginated.fromJson(dynamic raw, T Function(Map<String, dynamic>) f) {
    final j = jsonMap(raw);
    final p = jsonMap(j['pagination']);
    final items = (raw is List ? jsonList(raw) : jsonList(j['items']))
        .map(f)
        .toList();
    return Paginated(
      items,
      page: jsonInt(p['page']) ?? 1,
      pages: jsonInt(p['pages']) ?? 1,
      total: jsonInt(p['total']) ?? items.length,
    );
  }
}

/// Tournament lifecycle as the backend reports it. Never derived from the
/// device clock.
enum TStatus {
  draft,
  published,
  registrationOpen,
  registrationClosed,
  live,
  completed,
  cancelled,
  unknown;

  static TStatus parse(String? raw) => switch ((raw ?? '').toLowerCase()) {
    'draft' => draft,
    'published' => published,
    'registration_open' => registrationOpen,
    'registration_closed' => registrationClosed,
    'live' || 'in_progress' => live,
    'completed' => completed,
    'cancelled' || 'canceled' => cancelled,
    _ => unknown,
  };

  String get label => switch (this) {
    draft => 'Draft',
    published => 'Opens soon',
    registrationOpen => 'Registration open',
    registrationClosed => 'Registration closed',
    live => 'Live',
    completed => 'Completed',
    cancelled => 'Cancelled',
    unknown => 'Unknown',
  };

  bool get isTerminal => this == completed || this == cancelled;
}

class PrizeSplit {
  final int rank;
  final num percent;
  final num? amount;
  const PrizeSplit({required this.rank, required this.percent, this.amount});

  factory PrizeSplit.fromJson(Map<String, dynamic> j) => PrizeSplit(
    rank: jsonInt(j['rank']) ?? 0,
    percent: (j['percent'] as num?) ?? 0,
    amount: j['amount'] as num?,
  );

  Map<String, dynamic> toJson() => {'rank': rank, 'percent': percent};
}

class Tournament {
  final Map<String, dynamic> raw;
  const Tournament(this.raw);

  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
    jsonMap(j['tournament']).isNotEmpty ? jsonMap(j['tournament']) : j,
  );

  String get id => raw['id']?.toString() ?? '';
  String get title => jsonStr(raw['title']) ?? 'Tournament';
  String? get description => jsonStr(raw['description']);
  String get game => jsonStr(raw['game']) ?? '';
  String? get gameMode => jsonStr(raw['game_mode']);
  String? get platform => jsonStr(raw['platform']);
  String? get region => jsonStr(raw['region']);
  String? get organizationName => jsonStr(raw['organization_name']);
  String? get bannerUrl => jsonStr(raw['banner_url']);
  String? get bannerAssetId => jsonStr(raw['banner_asset_id']);
  int? get hostUserId => jsonInt(raw['host_user_id']);
  bool get canManage => raw['can_manage'] == true;
  String get format => jsonStr(raw['tournament_type']) ?? 'single_elimination';
  String get teamMode => jsonStr(raw['team_mode']) ?? 'solo';
  bool get isSolo => teamMode == 'solo';
  int get teamSize => jsonInt(raw['team_size']) ?? (isSolo ? 1 : 2);
  int get substituteLimit => jsonInt(raw['substitute_limit']) ?? 0;
  double get entryFee => jsonDouble(raw['entry_fee']);
  bool get isFree => entryFee <= 0;
  String get currency => jsonStr(raw['currency']) ?? 'INR';
  int get maxPlayers => jsonInt(raw['max_players']) ?? 0;
  int get registeredCount => jsonInt(raw['registered_players_count']) ?? 0;
  int? get minEntries => jsonInt(raw['min_entries']);
  int? get minimumAge => jsonInt(raw['minimum_age']);
  bool get isFull => maxPlayers > 0 && registeredCount >= maxPlayers;
  bool get isPrivate => raw['is_private'] == true;
  bool get requiresInviteCode => raw['requires_invite_code'] == true;
  String? get inviteCode => jsonStr(raw['invite_code']);
  bool get isFeatured => raw['is_featured'] == true;
  String? get registrationPolicy => jsonStr(raw['registration_policy']);
  String? get rules => jsonStr(raw['rules']);
  String? get discordLink => jsonStr(raw['discord_link']);
  String? get whatsappLink => jsonStr(raw['whatsapp_link']);
  String? get roomDetails => jsonStr(raw['room_details']);
  Map<String, dynamic> get roomDetailsData => jsonMap(raw['room_details_data']);
  Map<String, dynamic> get rulesConfig => jsonMap(raw['rules_config']);
  Map<String, dynamic> get scheduleConfig => jsonMap(raw['schedule_config']);
  TStatus get status => TStatus.parse(raw['status']?.toString());
  String get rawStatus => raw['status']?.toString() ?? '';
  DateTime? get registrationStartAt => jsonDate(raw['registration_start_at']);
  DateTime? get registrationEndAt => jsonDate(raw['registration_end_at']);
  DateTime? get startAt => jsonDate(raw['tournament_start_at']);
  DateTime? get endAt => jsonDate(raw['tournament_end_at']);
  DateTime? get rosterLockAt => jsonDate(raw['roster_lock_at']);
  DateTime? get checkInStartAt => jsonDate(raw['check_in_start_at']);
  DateTime? get checkInEndAt => jsonDate(raw['check_in_end_at']);
  int? get matchDurationMinutes => jsonInt(raw['match_duration_minutes']);
  int? get breakDurationMinutes => jsonInt(raw['break_duration_minutes']);
  int? get resultWindowMinutes =>
      jsonInt(raw['result_submission_window_minutes']);
  int? get disputeWindowMinutes => jsonInt(raw['dispute_window_minutes']);
  double get prizePool => jsonDouble(raw['prize_pool']);
  double get totalCollection => jsonDouble(raw['total_collection']);
  double get platformFee => jsonDouble(raw['platform_fee_amount']);
  double get organizerCommission =>
      jsonDouble(raw['organizer_commission_amount']);
  List<PrizeSplit> get prizeDistribution =>
      jsonList(raw['prize_distribution']).map(PrizeSplit.fromJson).toList();

  String get formatLabel => formatLabelOf(format);
  String get modeLabel => switch (teamMode) {
    'solo' => 'Solo',
    'duo' => 'Duo',
    'squad' => 'Squad',
    _ => '${teamSize}v$teamSize',
  };
}

String formatLabelOf(String f) => switch (f) {
  'single_elimination' => 'Single elimination',
  'double_elimination' => 'Double elimination',
  'round_robin' => 'Round robin',
  'group_knockout' => 'Groups + knockout',
  'battle_royale' => 'Battle royale',
  'league' => 'League',
  _ => f.replaceAll('_', ' '),
};

class Registration {
  final Map<String, dynamic> raw;
  const Registration(this.raw);
  factory Registration.fromJson(Map<String, dynamic> j) => Registration(j);

  String get id => raw['id']?.toString() ?? '';
  String get tournamentId => raw['tournament_id']?.toString() ?? '';
  int? get userId => jsonInt(raw['user_id']);
  String get status => jsonStr(raw['status']) ?? 'pending_payment';
  String get paymentStatus => jsonStr(raw['payment_status']) ?? 'unpaid';
  String? get refundStatus => jsonStr(raw['refund_status']);
  DateTime? get checkedInAt => jsonDate(raw['checked_in_at']);
  bool get isConfirmed => status == 'confirmed';
  bool get isPendingPayment => status == 'pending_payment';
  bool get isActive => isConfirmed || isPendingPayment;
  Map<String, dynamic> get gamer => jsonMap(raw['gamer']);
  String get gamerName =>
      jsonStr(gamer['display_name']) ??
      jsonStr(gamer['game_username']) ??
      'Player #${userId ?? '-'}';

  /// Provider checkout data returned for a paid entry, when present.
  Map<String, dynamic> get checkout {
    for (final k in const ['payment', 'checkout', 'payment_order']) {
      final m = jsonMap(raw[k]);
      if (m.isNotEmpty) return m;
    }
    return const {};
  }

  String get statusLabel => switch (status) {
    'pending_payment' => 'Payment pending',
    'confirmed' => 'Entry confirmed',
    'refund_pending' => 'Refund processing',
    'refunded' => 'Refunded',
    'cancelled' => 'Cancelled',
    _ => status.replaceAll('_', ' '),
  };
}

class TeamMember {
  final Map<String, dynamic> raw;
  const TeamMember(this.raw);

  int? get userId => jsonInt(raw['user_id'] ?? jsonMap(raw['gamer'])['id']);
  String get role => jsonStr(raw['role']) ?? 'player';
  bool get isCaptain => role == 'captain';
  String get gameId => jsonStr(raw['game_id']) ?? '';
  String get status =>
      jsonStr(raw['verification_status'] ?? raw['invitation_status']) ??
      'invited';
  bool get accepted =>
      isCaptain || const {'accepted', 'verified', 'active'}.contains(status);
  String get name =>
      jsonStr(jsonMap(raw['gamer'])['display_name']) ??
      jsonStr(raw['display_name']) ??
      (gameId.isNotEmpty ? gameId : 'Player #${userId ?? '-'}');

  Map<String, dynamic> toRosterJson() => {
    'user_id': userId,
    'game_id': gameId,
    'role': role,
  };
}

class Team {
  final Map<String, dynamic> raw;
  const Team(this.raw);
  factory Team.fromJson(Map<String, dynamic> j) => Team(j);

  String get id => raw['id']?.toString() ?? '';
  String get name => jsonStr(raw['name'] ?? raw['team_name']) ?? 'Team';
  String get status => jsonStr(raw['status']) ?? 'pending';
  int? get captainUserId => jsonInt(raw['captain_user_id']);
  int? get seed => jsonInt(raw['seed_number']);
  String? get registrationId => jsonStr(raw['registration_id']);
  DateTime? get checkedInAt => jsonDate(raw['checked_in_at']);
  DateTime? get rosterLockedAt => jsonDate(raw['roster_locked_at']);
  String? get reason =>
      jsonStr(raw['disqualification_reason'] ?? raw['rejection_reason']);
  int get warnings => jsonInt(raw['warning_count']) ?? 0;
  List<TeamMember> get members =>
      jsonList(raw['members'] ?? raw['roster']).map(TeamMember.new).toList();
  bool get isApproved => status == 'approved';
}

class TeamInvitation {
  final Map<String, dynamic> raw;
  const TeamInvitation(this.raw);

  Map<String, dynamic> get _t => jsonMap(raw['tournament']);
  Map<String, dynamic> get _team => jsonMap(raw['team']);
  String get tournamentId =>
      (raw['tournament_id'] ?? _t['id'] ?? _team['tournament_id'] ?? '')
          .toString();
  String get tournamentTitle =>
      jsonStr(raw['tournament_title'] ?? _t['title']) ?? 'Tournament';
  String get teamId => (raw['team_id'] ?? _team['id'] ?? '').toString();
  String get teamName => jsonStr(raw['team_name'] ?? _team['name']) ?? 'Team';
  String get role => jsonStr(raw['role']) ?? 'player';
  bool get canRespond => raw['can_respond'] != false;
}

class MatchRow {
  final Map<String, dynamic> raw;
  const MatchRow(this.raw);
  factory MatchRow.fromJson(Map<String, dynamic> j) => MatchRow(j);

  String get id => raw['id']?.toString() ?? '';
  String get status => jsonStr(raw['status']) ?? 'scheduled';
  String? get stage => jsonStr(raw['stage']);
  int? get round => jsonInt(raw['round_number']);
  int? get number => jsonInt(raw['match_number']);
  DateTime? get scheduledAt => jsonDate(raw['scheduled_at']);
  DateTime? get resultDueAt => jsonDate(raw['result_due_at']);
  String? get teamAId =>
      jsonStr(raw['team_a_id'] ?? jsonMap(raw['team_a'])['id']);
  String? get teamBId =>
      jsonStr(raw['team_b_id'] ?? jsonMap(raw['team_b'])['id']);
  int? get scoreA => jsonInt(raw['team_a_score']);
  int? get scoreB => jsonInt(raw['team_b_score']);
  String? get winnerTeamId => jsonStr(raw['winner_team_id']);
  List<String> get participantIds =>
      (raw['participant_team_ids'] as List?)?.map((e) => '$e').toList() ??
      const [];
  bool get isMultiTeam =>
      participantIds.length > 2 ||
      (teamAId == null && participantIds.isNotEmpty);
  List<Map<String, dynamic>> get standings => jsonList(raw['standings']);
  Map<String, dynamic> get lobby => jsonMap(raw['lobby_details']);
  bool get hasLobby => lobby.values.any((v) => jsonStr(v) != null);

  String? inlineName(String side) =>
      jsonStr(raw['team_${side}_name'] ?? jsonMap(raw['team_$side'])['name']);

  String get title {
    final parts = <String>[
      if (stage != null) stage!.replaceAll('_', ' '),
      if (round != null) 'Round $round',
      if (number != null) 'Match $number',
    ];
    return parts.isEmpty ? 'Match' : parts.join(' · ');
  }

  String get statusLabel => matchStatusLabel(status);
  bool get isFinished => status == 'completed' || status == 'cancelled';
}

String matchStatusLabel(String s) => switch (s) {
  'scheduled' => 'Scheduled',
  'ready' => 'Ready',
  'in_progress' => 'In progress',
  'awaiting_results' => 'Awaiting results',
  'result_pending' => 'Result in review',
  'disputed' => 'Disputed',
  'completed' => 'Completed',
  'cancelled' => 'Cancelled',
  _ => s.replaceAll('_', ' '),
};

class ResultProposal {
  final Map<String, dynamic> raw;
  const ResultProposal(this.raw);
  String get id => raw['id']?.toString() ?? '';
  String get status => jsonStr(raw['status']) ?? 'pending';
  String? get winnerTeamId => jsonStr(raw['winner_team_id']);
  int? get scoreA => jsonInt(raw['team_a_score']);
  int? get scoreB => jsonInt(raw['team_b_score']);
  DateTime? get expiresAt => jsonDate(raw['expires_at']);
  List<String> get acceptedTeamIds =>
      (raw['accepted_team_ids'] as List?)?.map((e) => '$e').toList() ??
      const [];
  List<String> get evidenceUrls => [
    ...((raw['evidence_urls'] as List?)?.map((e) => '$e') ?? const []),
    ...jsonList(
      raw['evidence'],
    ).map((e) => jsonStr(e['file_url']) ?? '').where((e) => e.isNotEmpty),
  ];
}

class ResultSubmission {
  final Map<String, dynamic> raw;
  const ResultSubmission(this.raw);
  String get teamId => raw['team_id']?.toString() ?? '';
  String get status => jsonStr(raw['status']) ?? 'submitted';
  String? get winnerTeamId => jsonStr(raw['winner_team_id']);
  int? get scoreA => jsonInt(raw['team_a_score']);
  int? get scoreB => jsonInt(raw['team_b_score']);
  int? get submittedBy => jsonInt(raw['submitted_by_user_id']);
}

/// `GET /matches/{id}/result-state`: the authority for match-level result
/// actions. Flags are read from `viewer`, `permissions` or the top level.
class ResultState {
  final Map<String, dynamic> raw;
  const ResultState(this.raw);

  Map<String, dynamic> get _viewer => {
    ...raw,
    ...jsonMap(raw['permissions']),
    ...jsonMap(raw['viewer']),
  };
  bool flag(String k) => _viewer[k] == true;

  MatchRow? get match =>
      jsonMap(raw['match']).isEmpty ? null : MatchRow(jsonMap(raw['match']));
  List<ResultProposal> get proposals => [
    ...jsonList(raw['proposals']).map(ResultProposal.new),
    if (jsonMap(raw['pending_proposal']).isNotEmpty &&
        jsonList(raw['proposals']).isEmpty)
      ResultProposal(jsonMap(raw['pending_proposal'])),
  ];
  ResultProposal? get pendingProposal {
    for (final p in proposals) {
      if (p.status == 'pending') return p;
    }
    return null;
  }

  List<ResultSubmission> get submissions => jsonList(
    raw['submissions'] ?? raw['captain_submissions'],
  ).map(ResultSubmission.new).toList();
  Dispute? get activeDispute {
    final d = jsonMap(raw['active_dispute'] ?? raw['dispute']);
    return d.isEmpty ? null : Dispute(d);
  }

  DateTime? get serverTime => jsonDate(raw['server_time']);
  bool get canAccept => flag('can_accept_pending_proposal');
  bool get canDisputeProposal => flag('can_dispute_pending_proposal');
  bool get canSubmit =>
      flag('can_submit_result') || flag('can_submit') || flag('is_captain');
  String? get viewerTeamId =>
      jsonStr(_viewer['team_id'] ?? _viewer['viewer_team_id']);
}

class Dispute {
  final Map<String, dynamic> raw;
  const Dispute(this.raw);
  factory Dispute.fromJson(Map<String, dynamic> j) => Dispute(j);

  String get id => raw['id']?.toString() ?? '';
  String get tournamentId => raw['tournament_id']?.toString() ?? '';
  String? get matchId => jsonStr(raw['match_id']);
  String get reason => jsonStr(raw['reason']) ?? 'Dispute';
  String? get description => jsonStr(raw['description']);
  String get status => jsonStr(raw['status']) ?? 'open';
  String? get adminComment => jsonStr(raw['admin_comment']);
  String? get resolution => jsonStr(raw['resolution_action']);
  DateTime? get deadline => jsonDate(raw['response_deadline_at']);
  DateTime? get createdAt => jsonDate(raw['created_at']);
  String? get chatRoomId => jsonStr(raw['chat_room_id']);
  bool get chatReady =>
      raw['chat_room_status'] == 'ready' && chatRoomId != null;
  String? get tournamentTitle =>
      jsonStr(raw['tournament_title'] ?? jsonMap(raw['tournament'])['title']);
  bool get isOpen => status == 'open' || status == 'under_review';
}

class Payout {
  final Map<String, dynamic> raw;
  const Payout(this.raw);
  factory Payout.fromJson(Map<String, dynamic> j) => Payout(j);

  String get id => raw['id']?.toString() ?? '';
  String get tournamentId => raw['tournament_id']?.toString() ?? '';
  int? get userId => jsonInt(raw['user_id']);
  int? get rank => jsonInt(raw['rank']);
  double get amount => jsonDouble(raw['amount']);
  String get currency => jsonStr(raw['currency']) ?? 'INR';
  String get status => jsonStr(raw['status']) ?? 'pending_admin_approval';
  String get type => jsonStr(raw['payout_type']) ?? 'prize';
  DateTime? get paidAt => jsonDate(raw['paid_at']);
  String get gamerName =>
      jsonStr(jsonMap(raw['gamer'])['display_name']) ??
      'Player #${userId ?? '-'}';
  String? get tournamentTitle =>
      jsonStr(raw['tournament_title'] ?? jsonMap(raw['tournament'])['title']);

  String get statusLabel => switch (status) {
    'pending_admin_approval' => 'Awaiting approval',
    'approved' => 'Approved, not yet paid',
    'paid' => 'Paid to Hash wallet',
    'failed' => 'Failed',
    'cancelled' => 'Cancelled',
    _ => status.replaceAll('_', ' '),
  };
}

class Announcement {
  final Map<String, dynamic> raw;
  const Announcement(this.raw);
  String get title => jsonStr(raw['title']) ?? 'Announcement';
  String get message => jsonStr(raw['message']) ?? '';
  String get audience => jsonStr(raw['audience']) ?? 'all_participants';
  DateTime? get publishedAt =>
      jsonDate(raw['published_at'] ?? raw['created_at']);
}

class LeaderboardRow {
  final Map<String, dynamic> raw;
  const LeaderboardRow(this.raw);
  int? get rank => jsonInt(raw['rank'] ?? raw['position']);
  String get teamId =>
      (raw['team_id'] ?? jsonMap(raw['team'])['id'] ?? '').toString();
  String get name =>
      jsonStr(
        raw['team_name'] ?? jsonMap(raw['team'])['name'] ?? raw['name'],
      ) ??
      'Team';
  num get points => (raw['points'] as num?) ?? 0;
  int? get wins => jsonInt(raw['wins']);
  int? get losses => jsonInt(raw['losses']);
  int? get kills => jsonInt(raw['kills']);
}

class Readiness {
  final bool ready;
  final List<String> blockers;
  final List<String> warnings;
  const Readiness(this.ready, this.blockers, this.warnings);
  factory Readiness.fromJson(Map<String, dynamic> j) => Readiness(
    j['ready_to_publish'] == true,
    jsonStrings(j['blockers']),
    jsonStrings(j['warnings']),
  );
}

/// The player-screen bootstrap, `GET /tournaments/{id}/me`.
class MyTournamentState {
  final Map<String, dynamic> raw;
  const MyTournamentState(this.raw);

  Tournament? get tournament => jsonMap(raw['tournament']).isEmpty
      ? null
      : Tournament(jsonMap(raw['tournament']));
  Registration? get registration => jsonMap(raw['registration']).isEmpty
      ? null
      : Registration(jsonMap(raw['registration']));
  Team? get team =>
      jsonMap(raw['team']).isEmpty ? null : Team(jsonMap(raw['team']));
  List<TeamInvitation> get invitations =>
      jsonList(raw['invitations']).map(TeamInvitation.new).toList();
  List<MatchRow> get matches =>
      jsonList(raw['matches']).map(MatchRow.new).toList();
  MatchRow? get currentMatch => jsonMap(raw['current_match']).isEmpty
      ? null
      : MatchRow(jsonMap(raw['current_match']));
  Map<String, dynamic> get _actions => jsonMap(raw['actions']);
  bool action(String k) => _actions[k] == true;

  bool get canManage => action('can_manage');
  bool get canJoin => action('can_join');
  bool get canContinuePayment => action('can_continue_payment');
  bool get canCheckIn => action('can_check_in');
  bool get canCancel => action('can_cancel_registration');
  bool get canViewMatch => action('can_view_match');
  bool get canPlay => action('can_play');
}

class FinalizationPreview {
  final Map<String, dynamic> raw;
  const FinalizationPreview(this.raw);
  bool get ready => raw['ready_to_finalize'] == true;
  bool get requiresWinnerSelection => raw['requires_winner_selection'] == true;
  List<String> get blockers => jsonStrings(raw['blockers']);
  String get currency => jsonStr(raw['currency']) ?? 'INR';
  List<Map<String, dynamic>> get payees => jsonList(raw['eligible_payees']);
  List<Map<String, dynamic>> get proposedAwards =>
      jsonList(raw['proposed_awards']);
  double get prizePool =>
      jsonDouble(raw['prize_pool'] ?? jsonMap(raw['totals'])['prize_pool']);
}

class FileAsset {
  final String id;
  final String? url;
  const FileAsset(this.id, this.url);
  factory FileAsset.fromJson(Map<String, dynamic> j) =>
      FileAsset(j['id']?.toString() ?? '', jsonStr(j['file_url']));
}

class HostProfile {
  final Map<String, dynamic> raw;
  const HostProfile(this.raw);
  bool get verified =>
      raw['verified'] == true || raw['verification_status'] == 'verified';
  double get rating =>
      jsonDouble(raw['participant_rating'] ?? raw['average_rating']);
  int get reviews => jsonInt(raw['review_count']) ?? 0;
  int get hosted => jsonInt(raw['hosted_count']) ?? 0;
  int get completed => jsonInt(raw['completed_count']) ?? 0;
  String? get name => jsonStr(raw['display_name'] ?? raw['name']);
}
