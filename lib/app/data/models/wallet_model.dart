class WalletModel {
  final double balance;
  final String currency;
  final List<WalletTransaction> transactions;
  final DateTime lastUpdated;

  WalletModel({
    required this.balance,
    this.currency = 'INR',
    this.transactions = const [],
    required this.lastUpdated,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((transaction) => WalletTransaction.fromJson(transaction))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
      'transactions': transactions.map((transaction) => transaction.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  WalletModel copyWith({
    double? balance,
    String? currency,
    List<WalletTransaction>? transactions,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      transactions: transactions ?? this.transactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class WalletTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? referenceId;
  final String? paymentMethod;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
    this.referenceId,
    this.paymentMethod,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.unknown,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      referenceId: json['reference_id'],
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'reference_id': referenceId,
      'payment_method': paymentMethod,
    };
  }
}

enum TransactionType {
  credit,
  debit,
  withdrawal,
  refund,
  unknown,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TopUpRequest {
  final double amount;
  final String paymentId;
  final String? description;

  TopUpRequest({
    required this.amount,
    required this.paymentId,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reference_id': paymentId,
      if (description != null) 'description': description,
    };
  }
}

class WithdrawalRequest {
  final double amount;
  final String bankAccount;
  final String? description;

  WithdrawalRequest({
    required this.amount,
    required this.bankAccount,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bank_account': bankAccount,
      if (description != null) 'description': description,
    };
  }
}
