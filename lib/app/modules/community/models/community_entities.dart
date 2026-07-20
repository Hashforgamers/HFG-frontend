// Lightweight models for host management, results, disputes, payouts, and files.

class GamerSummary {
  final int? id;
  final String displayName;
  final String gameUsername;
  final String? avatarUrl;

  const GamerSummary({
    required this.id,
    required this.displayName,
    required this.gameUsername,
    required this.avatarUrl,
  });

  factory GamerSummary.fromJson(Map<String, dynamic> j) => GamerSummary(
    id: (j['id'] as num?)?.toInt(),
    displayName: (j['display_name'] ?? j['name'] ?? 'Gamer').toString(),
    gameUsername: (j['game_username'] ?? '').toString(),
    avatarUrl: j['avatar_url']?.toString(),
  );
}

class ManagedRegistration {
  final String id;
  final int? userId;
  final String status;
  final String paymentStatus;
  final String? paymentReference;
  final DateTime? checkedInAt;
  final GamerSummary gamer;

  const ManagedRegistration({
    required this.id,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.paymentReference,
    required this.checkedInAt,
    required this.gamer,
  });

  factory ManagedRegistration.fromJson(Map<String, dynamic> j) =>
      ManagedRegistration(
        id: (j['id'] ?? '').toString(),
        userId: (j['user_id'] as num?)?.toInt(),
        status: (j['status'] ?? 'pending_payment').toString(),
        paymentStatus: (j['payment_status'] ?? 'unpaid').toString(),
        paymentReference: j['payment_reference']?.toString(),
        checkedInAt: DateTime.tryParse((j['checked_in_at'] ?? '').toString()),
        gamer: GamerSummary.fromJson(
          j['gamer'] is Map ? Map<String, dynamic>.from(j['gamer']) : const {},
        ),
      );
}

class MatchResult {
  final String id;
  final String tournamentId;
  final int? winnerUserId;
  final int? rank;
  final String? score;
  final List<String> evidenceAssetIds;
  final String? streamUrl;
  final String? notes;
  final String status; // submitted | verified | rejected | admin_overridden
  final GamerSummary? winner;
  final GamerSummary? submittedBy;

  const MatchResult({
    required this.id,
    required this.tournamentId,
    required this.winnerUserId,
    required this.rank,
    required this.score,
    required this.evidenceAssetIds,
    required this.streamUrl,
    required this.notes,
    required this.status,
    required this.winner,
    required this.submittedBy,
  });

  factory MatchResult.fromJson(Map<String, dynamic> j) => MatchResult(
    id: (j['id'] ?? '').toString(),
    tournamentId: (j['tournament_id'] ?? '').toString(),
    winnerUserId: (j['winner_user_id'] as num?)?.toInt(),
    rank: (j['rank'] as num?)?.toInt(),
    score: j['score'] as String?,
    evidenceAssetIds:
        (j['evidence_asset_ids'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    streamUrl: j['stream_url'] as String?,
    notes: j['notes'] as String?,
    status: (j['status'] as String?) ?? 'submitted',
    winner: j['winner'] is Map
        ? GamerSummary.fromJson(Map<String, dynamic>.from(j['winner']))
        : null,
    submittedBy: j['submitted_by'] is Map
        ? GamerSummary.fromJson(Map<String, dynamic>.from(j['submitted_by']))
        : null,
  );
}

class Dispute {
  final String id;
  final String tournamentId;
  final String? resultId;
  final String reason;
  final String description;
  final String status; // open | under_review | approved | rejected | closed
  final GamerSummary? reporter;

  const Dispute({
    required this.id,
    required this.tournamentId,
    required this.resultId,
    required this.reason,
    required this.description,
    required this.status,
    required this.reporter,
  });

  factory Dispute.fromJson(Map<String, dynamic> j) => Dispute(
    id: (j['id'] ?? '').toString(),
    tournamentId: (j['tournament_id'] ?? '').toString(),
    resultId: j['result_id'] as String?,
    reason: (j['reason'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'open',
    reporter: j['reporter'] is Map
        ? GamerSummary.fromJson(Map<String, dynamic>.from(j['reporter']))
        : null,
  );
}

class Payout {
  final String id;
  final int? userId;
  final int? rank;
  final double amount;
  final String status;
  final String currency;
  final GamerSummary? gamer;

  const Payout({
    required this.id,
    required this.userId,
    required this.rank,
    required this.amount,
    required this.status,
    required this.currency,
    required this.gamer,
  });

  factory Payout.fromJson(Map<String, dynamic> j) => Payout(
    id: (j['id'] ?? '').toString(),
    userId: (j['user_id'] as num?)?.toInt(),
    rank: (j['rank'] as num?)?.toInt(),
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    status: (j['status'] as String?) ?? 'pending_admin_approval',
    currency: (j['currency'] ?? 'INR').toString(),
    gamer: j['gamer'] is Map
        ? GamerSummary.fromJson(Map<String, dynamic>.from(j['gamer']))
        : null,
  );
}

class FileAsset {
  final String id;
  final int? ownerUserId;
  final String? tournamentId;
  final String purpose;
  final String? fileUrl;
  final String? storageKey;
  final String? mimeType;
  final int? fileSizeBytes;

  const FileAsset({
    required this.id,
    required this.ownerUserId,
    required this.tournamentId,
    required this.purpose,
    required this.fileUrl,
    required this.storageKey,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  factory FileAsset.fromJson(Map<String, dynamic> j) => FileAsset(
    id: (j['id'] ?? '').toString(),
    ownerUserId: (j['owner_user_id'] as num?)?.toInt(),
    tournamentId: j['tournament_id'] as String?,
    purpose: (j['purpose'] as String?) ?? '',
    fileUrl: j['file_url'] as String?,
    storageKey: j['storage_key'] as String?,
    mimeType: j['mime_type'] as String?,
    fileSizeBytes: (j['file_size_bytes'] as num?)?.toInt(),
  );
}
