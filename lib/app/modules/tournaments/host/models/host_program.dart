// Models for GET /api/v1/community/hosts/program
//
// Renders host onboarding pricing (verification fee) and the performance-tier
// benefits table. Values are backend-owned; always render what the API returns
// rather than hardcoding amounts.

class HostVerificationFee {
  final double amount;
  final String currency;
  final String billingPeriod; // e.g. "monthly", "one-time"
  final int includedTournamentsPerWeek;

  const HostVerificationFee({
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.includedTournamentsPerWeek,
  });

  factory HostVerificationFee.fromJson(Map<String, dynamic> json) {
    return HostVerificationFee(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'INR',
      billingPeriod: (json['billing_period'] as String?) ?? 'monthly',
      includedTournamentsPerWeek:
          (json['included_tournaments_per_week'] as num?)?.toInt() ?? 0,
    );
  }

  /// "monthly" -> "/mo", "one-time"/"one_time" -> "one-time", else the raw value.
  String get periodLabel {
    switch (billingPeriod.toLowerCase()) {
      case 'monthly':
        return 'per month';
      case 'one-time':
      case 'one_time':
        return 'one-time';
      default:
        return billingPeriod;
    }
  }
}

class HostTierLevel {
  final String key; // bronze | silver | gold | platinum
  final String label;
  final double organizerCommissionRate;
  final List<String> requirements;

  const HostTierLevel({
    required this.key,
    required this.label,
    required this.organizerCommissionRate,
    required this.requirements,
  });

  factory HostTierLevel.fromJson(String key, Map<String, dynamic> json) {
    return HostTierLevel(
      key: key,
      label: (json['label'] as String?) ?? key,
      organizerCommissionRate:
          (json['organizer_commission_rate'] as num?)?.toDouble() ?? 0,
      requirements:
          (json['requirements'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class HostProgram {
  final HostVerificationFee verificationFee;
  final List<HostTierLevel> performanceLevels;

  const HostProgram({
    required this.verificationFee,
    required this.performanceLevels,
  });

  factory HostProgram.fromJson(Map<String, dynamic> json) {
    final levelsRaw = (json['performance_levels'] as Map?) ?? const {};
    // Preserve a sensible tier order regardless of JSON key ordering.
    const order = ['bronze', 'silver', 'gold', 'platinum'];
    final levels = <HostTierLevel>[];
    for (final key in order) {
      final value = levelsRaw[key];
      if (value is Map) {
        levels.add(
          HostTierLevel.fromJson(key, Map<String, dynamic>.from(value)),
        );
      }
    }
    // Include any extra tiers the backend adds that aren't in the known order.
    levelsRaw.forEach((key, value) {
      if (!order.contains(key) && value is Map) {
        levels.add(
          HostTierLevel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      }
    });

    return HostProgram(
      verificationFee: HostVerificationFee.fromJson(
        Map<String, dynamic>.from((json['verification_fee'] as Map?) ?? {}),
      ),
      performanceLevels: levels,
    );
  }
}
