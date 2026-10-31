// Models for the Community Tournament module (tournaments + registrations).

import 'tournament_domain.dart';

class PrizeSplit {
  final int rank;
  final num percent;
  const PrizeSplit({required this.rank, required this.percent});

  factory PrizeSplit.fromJson(Map<String, dynamic> j) => PrizeSplit(
    rank: (j['rank'] as num?)?.toInt() ?? 0,
    percent: (j['percent'] as num?) ?? 0,
  );

  Map<String, dynamic> toJson() => {'rank': rank, 'percent': percent};
}

class RoomDetailsData {
  static const _knownKeys = {
    'schema_version',
    'join',
    'schedule',
    'contacts',
    'custom_fields',
  };

  final int schemaVersion;
  final Map<String, dynamic> join;
  final Map<String, dynamic> schedule;
  final List<Map<String, dynamic>> contacts;
  final List<Map<String, dynamic>> customFields;
  final Map<String, dynamic> additionalFields;

  const RoomDetailsData({
    this.schemaVersion = 1,
    this.join = const {},
    this.schedule = const {},
    this.contacts = const [],
    this.customFields = const [],
    this.additionalFields = const {},
  });

  factory RoomDetailsData.fromJson(Map<String, dynamic> json) {
    final additional = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) {
        additional[entry.key] = _cloneJsonValue(entry.value);
      }
    }
    return RoomDetailsData(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      join: _jsonMap(json['join']),
      schedule: _jsonMap(json['schedule']),
      contacts: _jsonMapList(json['contacts']),
      customFields: _jsonMapList(json['custom_fields']),
      additionalFields: additional,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...additionalFields.map(
      (key, value) => MapEntry(key, _cloneJsonValue(value)),
    ),
    'schema_version': schemaVersion,
    if (join.isNotEmpty) 'join': _cloneJsonMap(join),
    if (schedule.isNotEmpty) 'schedule': _cloneJsonMap(schedule),
    if (contacts.isNotEmpty) 'contacts': contacts.map(_cloneJsonMap).toList(),
    if (customFields.isNotEmpty)
      'custom_fields': customFields.map(_cloneJsonMap).toList(),
  };

  static Map<String, dynamic> _jsonMap(dynamic value) => value is Map
      ? Map<String, dynamic>.from(
          value,
        ).map((key, item) => MapEntry(key, _cloneJsonValue(item)))
      : <String, dynamic>{};

  static List<Map<String, dynamic>> _jsonMapList(dynamic value) => value is List
      ? value.whereType<Map>().map(_jsonMap).toList()
      : <Map<String, dynamic>>[];

  static Map<String, dynamic> _cloneJsonMap(Map<String, dynamic> value) =>
      value.map((key, item) => MapEntry(key, _cloneJsonValue(item)));

  static dynamic _cloneJsonValue(dynamic value) {
    if (value is Map) return _jsonMap(value);
    if (value is List) return value.map(_cloneJsonValue).toList();
    return value;
  }
}

class Tournament {
  final String id;
  final int? hostUserId;
  final String? hostFirebaseUid;
  final bool canManage;
  final String title;
  final String? description;
  final String? bannerAssetId;
  final String? bannerUrl;
  final String game;
  final String? tournamentType;
  final String? teamMode;
  final double entryFee;
  final String currency;
  final int maxPlayers;
  final DateTime? registrationStartAt;
  final DateTime? registrationEndAt;
  final DateTime? tournamentStartAt;
  final DateTime? tournamentEndAt;
  final int? matchDurationMinutes;
  final int? breakDurationMinutes;
  final int concurrentMatches;
  final String? gameMode;
  final String? platform;
  final String? organizationName;
  final int? teamSize;
  final int? substituteLimit;
  final int? minimumAge;
  final String? region;
  final String? registrationPolicy;
  final bool isPrivate;
  final String? inviteCode;
  final int? minEntries;
  final DateTime? rosterLockAt;
  final DateTime? checkInStartAt;
  final DateTime? checkInEndAt;
  final int? maxMatchesPerTeamPerDay;
  final int? resultSubmissionWindowMinutes;
  final int? disputeWindowMinutes;
  final bool evidenceRequired;
  final String? rules;
  final List<PrizeSplit> prizeDistribution;
  final String? discordLink;
  final String? whatsappLink;
  final String? roomDetails; // present only for host/confirmed participant
  final RoomDetailsData? roomDetailsData;
  final bool visibility;
  final bool isFeatured;
  final String status;
  final double totalCollection;
  final double platformFeeAmount;
  final String hostTier;
  final double organizerCommissionRate;
  final double organizerCommissionAmount;
  final double prizePool;
  final int registeredPlayersCount;

  const Tournament({
    required this.id,
    required this.hostUserId,
    this.hostFirebaseUid,
    this.canManage = false,
    required this.title,
    required this.description,
    required this.bannerAssetId,
    required this.bannerUrl,
    required this.game,
    required this.tournamentType,
    required this.teamMode,
    required this.entryFee,
    required this.currency,
    required this.maxPlayers,
    required this.registrationStartAt,
    required this.registrationEndAt,
    required this.tournamentStartAt,
    required this.tournamentEndAt,
    this.matchDurationMinutes,
    this.breakDurationMinutes,
    this.concurrentMatches = 1,
    this.gameMode,
    this.platform,
    this.organizationName,
    this.teamSize,
    this.substituteLimit,
    this.minimumAge,
    this.region,
    this.registrationPolicy,
    this.isPrivate = false,
    this.inviteCode,
    this.minEntries,
    this.rosterLockAt,
    this.checkInStartAt,
    this.checkInEndAt,
    this.maxMatchesPerTeamPerDay,
    this.resultSubmissionWindowMinutes,
    this.disputeWindowMinutes,
    this.evidenceRequired = false,
    required this.rules,
    required this.prizeDistribution,
    required this.discordLink,
    required this.whatsappLink,
    required this.roomDetails,
    required this.roomDetailsData,
    required this.visibility,
    required this.isFeatured,
    required this.status,
    required this.totalCollection,
    required this.platformFeeAmount,
    required this.hostTier,
    required this.organizerCommissionRate,
    required this.organizerCommissionAmount,
    required this.prizePool,
    required this.registeredPlayersCount,
  });

  bool get isFree => entryFee <= 0;
  bool get isFull => registeredPlayersCount >= maxPlayers;
  TournamentStatus get statusValue => tournamentStatusFrom(status);
  bool get canRegister =>
      statusValue == TournamentStatus.registrationOpen && !isFull;

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static String? _hostFid(Map<String, dynamic> json) {
    String? read(dynamic value) {
      if (value is! Map) return null;
      final map = Map<String, dynamic>.from(value);
      for (final key in const [
        'fid',
        'firebase_uid',
        'firebase_fid',
        'firebase_id',
      ]) {
        final candidate = map[key]?.toString().trim() ?? '';
        if (candidate.isNotEmpty) return candidate;
      }
      for (final key in const ['user', 'gamer', 'profile', 'account']) {
        final nested = read(map[key]);
        if (nested != null) return nested;
      }
      return null;
    }

    for (final key in const [
      'host_fid',
      'host_firebase_uid',
      'host_firebase_id',
    ]) {
      final candidate = json[key]?.toString().trim() ?? '';
      if (candidate.isNotEmpty) return candidate;
    }
    for (final key in const ['host', 'host_user', 'organizer', 'creator']) {
      final candidate = read(json[key]);
      if (candidate != null) return candidate;
    }
    return null;
  }

  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
    id: (j['id'] ?? '').toString(),
    hostUserId: (j['host_user_id'] as num?)?.toInt(),
    hostFirebaseUid: _hostFid(j),
    canManage: j['can_manage'] == true,
    title: (j['title'] as String?) ?? '',
    description: j['description'] as String?,
    bannerAssetId: j['banner_asset_id'] as String?,
    bannerUrl: j['banner_url'] as String?,
    game: (j['game'] as String?) ?? '',
    tournamentType: j['tournament_type'] as String?,
    teamMode: j['team_mode'] as String?,
    entryFee: (j['entry_fee'] as num?)?.toDouble() ?? 0,
    currency: (j['currency'] as String?) ?? 'INR',
    maxPlayers: (j['max_players'] as num?)?.toInt() ?? 0,
    registrationStartAt: _dt(j['registration_start_at']),
    registrationEndAt: _dt(j['registration_end_at']),
    tournamentStartAt: _dt(j['tournament_start_at']),
    tournamentEndAt: _dt(j['tournament_end_at']),
    matchDurationMinutes: (j['match_duration_minutes'] as num?)?.toInt(),
    breakDurationMinutes: (j['break_duration_minutes'] as num?)?.toInt(),
    concurrentMatches:
        (j['schedule_config'] is Map
                ? (j['schedule_config'] as Map)['concurrent_matches'] as num?
                : null)
            ?.toInt() ??
        1,
    gameMode: j['game_mode']?.toString(),
    platform: j['platform']?.toString(),
    organizationName: j['organization_name']?.toString(),
    teamSize: (j['team_size'] as num?)?.toInt(),
    substituteLimit: (j['substitute_limit'] as num?)?.toInt(),
    minimumAge: (j['minimum_age'] as num?)?.toInt(),
    region: j['region']?.toString(),
    registrationPolicy: j['registration_policy']?.toString(),
    isPrivate: j['is_private'] == true,
    inviteCode: j['invite_code']?.toString(),
    minEntries: (j['min_entries'] as num?)?.toInt(),
    rosterLockAt: _dt(j['roster_lock_at']),
    checkInStartAt: _dt(j['check_in_start_at']),
    checkInEndAt: _dt(j['check_in_end_at']),
    maxMatchesPerTeamPerDay: (j['max_matches_per_team_per_day'] as num?)
        ?.toInt(),
    resultSubmissionWindowMinutes:
        (j['result_submission_window_minutes'] as num?)?.toInt(),
    disputeWindowMinutes: (j['dispute_window_minutes'] as num?)?.toInt(),
    evidenceRequired:
        j['rules_config'] is Map &&
        (j['rules_config'] as Map)['evidence_required'] == true,
    rules: j['rules'] as String?,
    prizeDistribution:
        (j['prize_distribution'] as List?)
            ?.whereType<Map>()
            .map((e) => PrizeSplit.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    discordLink: j['discord_link'] as String?,
    whatsappLink: j['whatsapp_link'] as String?,
    roomDetails: j['room_details'] as String?,
    roomDetailsData: j['room_details_data'] is Map
        ? RoomDetailsData.fromJson(
            Map<String, dynamic>.from(j['room_details_data'] as Map),
          )
        : null,
    visibility: (j['visibility'] as bool?) ?? true,
    isFeatured: (j['is_featured'] as bool?) ?? false,
    status: (j['status'] as String?) ?? 'draft',
    totalCollection: (j['total_collection'] as num?)?.toDouble() ?? 0,
    platformFeeAmount: (j['platform_fee_amount'] as num?)?.toDouble() ?? 0,
    hostTier: (j['host_tier'] as String?) ?? 'bronze',
    organizerCommissionRate:
        (j['organizer_commission_rate'] as num?)?.toDouble() ?? 0,
    organizerCommissionAmount:
        (j['organizer_commission_amount'] as num?)?.toDouble() ?? 0,
    prizePool: (j['prize_pool'] as num?)?.toDouble() ?? 0,
    registeredPlayersCount:
        (j['registered_players_count'] as num?)?.toInt() ?? 0,
  );
}

class Registration {
  final String id;
  final String tournamentId;
  final int? userId;
  final String status; // pending_payment | confirmed | cancelled | refunded
  final String paymentStatus;
  final double amountPaid;
  final String? paymentReference;

  const Registration({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.amountPaid,
    required this.paymentReference,
  });

  factory Registration.fromJson(Map<String, dynamic> j) => Registration(
    id: (j['id'] ?? '').toString(),
    tournamentId: (j['tournament_id'] ?? '').toString(),
    userId: (j['user_id'] as num?)?.toInt(),
    status: (j['status'] as String?) ?? 'pending_payment',
    paymentStatus: (j['payment_status'] as String?) ?? 'unpaid',
    amountPaid: (j['amount_paid'] as num?)?.toDouble() ?? 0,
    paymentReference: j['payment_reference'] as String?,
  );

  RegistrationStatus get statusValue => registrationStatusFrom(status);
}

/// A tournament list item may carry an embedded `registration` (role=joined).
class TournamentListItem {
  final Tournament tournament;
  final Registration? registration;
  const TournamentListItem({required this.tournament, this.registration});

  factory TournamentListItem.fromJson(Map<String, dynamic> j) {
    final reg = j['registration'];
    return TournamentListItem(
      tournament: Tournament.fromJson(j),
      registration: reg is Map
          ? Registration.fromJson(Map<String, dynamic>.from(reg))
          : null,
    );
  }
}

class Paginated<T> {
  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final int pages;

  const Paginated({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.pages,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) item,
  ) {
    final p = (j['pagination'] as Map?) ?? const {};
    return Paginated<T>(
      items:
          (j['items'] as List?)
              ?.whereType<Map>()
              .map((e) => item(Map<String, dynamic>.from(e)))
              .toList() ??
          <T>[],
      page: (p['page'] as num?)?.toInt() ?? 1,
      perPage: (p['per_page'] as num?)?.toInt() ?? 20,
      total: (p['total'] as num?)?.toInt() ?? 0,
      pages: (p['pages'] as num?)?.toInt() ?? 0,
    );
  }
}
