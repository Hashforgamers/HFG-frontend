// Model for GET /api/v1/community/hosts/me/verification
//
// The endpoint returns the host verification record for the current user,
// or null when the user has never applied. The `verification_status` drives
// the onboarding CTA state.

enum HostVerificationStatus {
  none,
  draft,
  paymentPending,
  pending,
  submitted,
  underReview,
  verified,
  rejected,
  suspended,
  unknown,
}

HostVerificationStatus hostVerificationStatusFrom(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case '':
    case 'none':
    case 'not_submitted':
      return HostVerificationStatus.none;
    case 'draft':
      return HostVerificationStatus.draft;
    case 'payment_pending':
      return HostVerificationStatus.paymentPending;
    case 'pending':
      return HostVerificationStatus.pending;
    case 'submitted':
      return HostVerificationStatus.submitted;
    case 'under_review':
      return HostVerificationStatus.underReview;
    case 'verified':
      return HostVerificationStatus.verified;
    case 'rejected':
      return HostVerificationStatus.rejected;
    case 'suspended':
      return HostVerificationStatus.suspended;
    default:
      return HostVerificationStatus.unknown;
  }
}

class HostVerification {
  final String id;
  final int? userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? governmentIdReference;
  final String? upiId;
  final String? address;
  final HostVerificationStatus status;
  final String hostTier;
  final double averageRating;
  final double disputeRate;
  final double completionRate;
  final double onTimePayoutRate;
  final int policyViolationCount;
  final String? rejectionReason;
  final String? suspensionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? updatedAt;

  const HostVerification({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.governmentIdReference,
    required this.upiId,
    required this.address,
    required this.status,
    required this.hostTier,
    required this.averageRating,
    required this.disputeRate,
    required this.completionRate,
    required this.onTimePayoutRate,
    required this.policyViolationCount,
    required this.rejectionReason,
    this.suspensionReason,
    this.createdAt,
    this.reviewedAt,
    this.updatedAt,
  });

  String? get maskedUpiId {
    final value = upiId?.trim();
    if (value == null || value.isEmpty) return null;
    final at = value.indexOf('@');
    if (at <= 0) return '••••';
    final name = value.substring(0, at);
    final visible = name.length <= 2
        ? name.substring(0, 1)
        : name.substring(0, 2);
    return '$visible${'•' * (name.length - visible.length)}${value.substring(at)}';
  }

  factory HostVerification.fromJson(Map<String, dynamic> json) {
    return HostVerification(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      governmentIdReference: json['government_id_reference'] as String?,
      upiId: json['upi_id'] as String?,
      address: json['address'] as String?,
      status: hostVerificationStatusFrom(
        json['verification_status'] as String?,
      ),
      hostTier: (json['host_tier'] as String?) ?? 'bronze',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      disputeRate: (json['dispute_rate'] as num?)?.toDouble() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      onTimePayoutRate: (json['on_time_payout_rate'] as num?)?.toDouble() ?? 0,
      policyViolationCount:
          (json['policy_violation_count'] as num?)?.toInt() ?? 0,
      rejectionReason: json['rejection_reason'] as String?,
      suspensionReason: json['suspension_reason'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      reviewedAt: DateTime.tryParse((json['reviewed_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }
}
