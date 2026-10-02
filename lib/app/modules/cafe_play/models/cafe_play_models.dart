// Models for the cafe "scan & play" flow (dashboard `/api/cafe/*`).
//
// Cafe money is always integer INR paise (10000 == ₹100.00) and the balance
// belongs to a single cafe — it is not the Hash Wallet.

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

class CafeDuration {
  const CafeDuration({required this.minutes, required this.amount});

  final int minutes;

  /// Paise.
  final int amount;

  factory CafeDuration.fromJson(Map<String, dynamic> json) => CafeDuration(
    minutes: _int(json['minutes']),
    amount: _int(json['amount']),
  );

  String get label {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

class CafePolicy {
  const CafePolicy({
    required this.selfService,
    required this.foodOrdering,
    required this.durations,
  });

  final bool selfService;
  final bool foodOrdering;
  final List<CafeDuration> durations;

  factory CafePolicy.fromJson(Map<String, dynamic>? json) {
    final raw = json?['durations'];
    return CafePolicy(
      selfService: json?['self_service'] == true,
      foodOrdering: json?['food_ordering'] == true,
      durations: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => CafeDuration.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

class CafeBookingOption {
  const CafeBookingOption({
    required this.bookingId,
    required this.gameName,
    required this.startsAt,
    required this.endsAt,
    required this.canStart,
    required this.reason,
  });

  /// Group anchor to submit.
  final int bookingId;
  final String gameName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool canStart;
  final String? reason;

  factory CafeBookingOption.fromJson(Map<String, dynamic> json) =>
      CafeBookingOption(
        bookingId: _int(json['booking_id']),
        gameName: (json['game_name'] ?? 'Booking').toString(),
        startsAt: _date(json['starts_at']),
        endsAt: _date(json['ends_at']),
        canStart: json['can_start'] == true,
        reason: json['reason']?.toString(),
      );
}

class CafeCheckout {
  const CafeCheckout({
    required this.cafeName,
    required this.consoleNumber,
    required this.vendorId,
    required this.consoleId,
    required this.policy,
    required this.availableBalance,
    required this.bookings,
    required this.activeSessionId,
  });

  final String cafeName;
  final int consoleNumber;
  final int vendorId;
  final int consoleId;
  final CafePolicy policy;

  /// Paise, already net of reserved funds.
  final int availableBalance;
  final List<CafeBookingOption> bookings;
  final String? activeSessionId;

  factory CafeCheckout.fromJson(Map<String, dynamic> json) {
    final rawBookings = json['bookings'];
    final active = json['active_session_id']?.toString();
    return CafeCheckout(
      cafeName: (json['cafe_name'] ?? 'Cafe').toString(),
      consoleNumber: _int(json['console_number']),
      vendorId: _int(json['vendor_id']),
      consoleId: _int(json['console_id']),
      policy: CafePolicy.fromJson(
        json['policy'] is Map
            ? Map<String, dynamic>.from(json['policy'])
            : null,
      ),
      availableBalance: _int(json['available_balance']),
      bookings: rawBookings is List
          ? rawBookings
                .whereType<Map>()
                .map(
                  (e) =>
                      CafeBookingOption.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      activeSessionId: (active == null || active.isEmpty) ? null : active,
    );
  }
}

enum CafeSessionState {
  reserved,
  active,
  failed,
  completed,
  cancelled,
  unknown,
}

class CafeSession {
  const CafeSession({
    required this.id,
    required this.state,
    required this.kind,
    required this.amount,
    required this.minutes,
    required this.deadline,
    required this.startedAt,
    required this.endsAt,
    required this.checkout,
  });

  final String id;
  final CafeSessionState state;

  /// `wallet` or `existing_booking`.
  final String kind;

  /// Paise; zero for existing bookings.
  final int amount;
  final int minutes;
  final DateTime? deadline;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final CafeCheckout? checkout;

  bool get isTerminal =>
      state == CafeSessionState.failed ||
      state == CafeSessionState.completed ||
      state == CafeSessionState.cancelled;

  factory CafeSession.fromJson(Map<String, dynamic> json) {
    final state = switch (json['state']?.toString()) {
      'reserved' => CafeSessionState.reserved,
      'active' => CafeSessionState.active,
      'failed' => CafeSessionState.failed,
      'completed' => CafeSessionState.completed,
      'cancelled' => CafeSessionState.cancelled,
      _ => CafeSessionState.unknown,
    };
    return CafeSession(
      id: json['id'].toString(),
      state: state,
      kind: (json['kind'] ?? 'wallet').toString(),
      amount: _int(json['amount']),
      minutes: _int(json['minutes']),
      deadline: _date(json['deadline']),
      startedAt: _date(json['started_at']),
      endsAt: _date(json['ends_at']),
      checkout: json['checkout'] is Map
          ? CafeCheckout.fromJson(Map<String, dynamic>.from(json['checkout']))
          : null,
    );
  }
}

/// One gamer's balance at one cafe (`/api/cafe/wallets`, `/api/cafe/{id}/wallet`).
class CafeWallet {
  const CafeWallet({
    required this.vendorId,
    required this.cafeName,
    required this.balance,
    required this.reserved,
    required this.availableBalance,
  });

  final int vendorId;
  final String cafeName;

  /// Paise.
  final int balance;

  /// Paise held for a session that hasn't been charged yet.
  final int reserved;

  /// Paise; `balance - reserved`.
  final int availableBalance;

  factory CafeWallet.fromJson(Map<String, dynamic> json) => CafeWallet(
    vendorId: _int(json['vendor_id']),
    cafeName: (json['cafe_name'] ?? 'Cafe').toString(),
    balance: _int(json['balance']),
    reserved: _int(json['reserved']),
    availableBalance: _int(json['available_balance']),
  );
}

enum CafeWalletEntryKind {
  topup,
  capture,
  refund,
  adjustment,
  reserve,
  release,
  unknown,
}

/// A cafe wallet ledger entry (`/api/cafe/{id}/wallet/history`).
class CafeWalletEntry {
  const CafeWalletEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.balanceAfter,
    required this.reservedAfter,
    required this.method,
    required this.createdAt,
  });

  final int id;
  final CafeWalletEntryKind kind;

  /// Signed paise; the sign (not the kind) decides credit vs debit.
  final int amount;
  final int balanceAfter;
  final int reservedAfter;

  /// `cash` or `cafe_upi` for top-ups.
  final String? method;
  final DateTime? createdAt;

  /// Reserve/release entries move held funds, not money.
  bool get isHold =>
      kind == CafeWalletEntryKind.reserve ||
      kind == CafeWalletEntryKind.release;

  String get label => switch (kind) {
    CafeWalletEntryKind.topup => 'Added at cafe',
    CafeWalletEntryKind.capture => 'Gaming charge',
    CafeWalletEntryKind.refund => 'Transaction reversed',
    CafeWalletEntryKind.adjustment => 'Cafe balance adjustment',
    CafeWalletEntryKind.reserve => 'Session funds reserved',
    CafeWalletEntryKind.release => 'Session reservation released',
    CafeWalletEntryKind.unknown => 'Wallet activity',
  };

  String? get methodLabel => switch (method) {
    'cash' => 'Cash',
    'cafe_upi' => 'UPI at cafe',
    _ => null,
  };

  factory CafeWalletEntry.fromJson(Map<String, dynamic> json) {
    final kind = switch (json['kind']?.toString()) {
      'topup' => CafeWalletEntryKind.topup,
      'capture' => CafeWalletEntryKind.capture,
      'refund' => CafeWalletEntryKind.refund,
      'adjustment' => CafeWalletEntryKind.adjustment,
      'reserve' => CafeWalletEntryKind.reserve,
      'release' => CafeWalletEntryKind.release,
      _ => CafeWalletEntryKind.unknown,
    };
    final method = json['method']?.toString();
    return CafeWalletEntry(
      id: _int(json['id']),
      kind: kind,
      amount: _int(json['amount']),
      balanceAfter: _int(json['balance_after']),
      reservedAfter: _int(json['reserved_after']),
      method: (method == null || method.isEmpty) ? null : method,
      createdAt: _date(json['created_at']),
    );
  }
}

/// A cursor page; [nextCursor] is null when there are no more rows.
class CafePage<T> {
  const CafePage({required this.items, required this.nextCursor});

  final List<T> items;
  final int? nextCursor;

  static CafePage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    final raw = json['items'];
    final cursor = json['next_cursor'];
    return CafePage(
      items: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => item(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      nextCursor: cursor == null ? null : _int(cursor, 0),
    );
  }
}

class CafePlayException implements Exception {
  const CafePlayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnknownOutcome => statusCode == null;

  @override
  String toString() => message;
}
