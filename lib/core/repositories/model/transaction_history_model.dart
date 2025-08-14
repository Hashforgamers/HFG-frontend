class TransactionHistoryModel {
  final int amount;
  final String date;
  final String id;
  final String referenceId;
  final String time;
  final String type;

  TransactionHistoryModel({
    required this.amount,
    required this.date,
    required this.id,
    required this.referenceId,
    required this.time,
    required this.type,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    // Handle both int and double values for amount
    int amount;
    if (json['amount'] is int) {
      amount = json['amount'];
    } else if (json['amount'] is double) {
      amount = (json['amount'] as double).round();
    } else {
      amount = 0;
    }
    
    return TransactionHistoryModel(
      amount: amount,
      date: json['date'] ?? '',
      id: json['id'] ?? '',
      referenceId: json['reference_id'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date,
      'id': id,
      'reference_id': referenceId,
      'time': time,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'TransactionHistoryModel(amount: $amount, date: $date, id: $id, referenceId: $referenceId, time: $time, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionHistoryModel &&
        other.amount == amount &&
        other.date == date &&
        other.id == id &&
        other.referenceId == referenceId &&
        other.time == time &&
        other.type == type;
  }

  @override
  int get hashCode {
    return amount.hashCode ^
        date.hashCode ^
        id.hashCode ^
        referenceId.hashCode ^
        time.hashCode ^
        type.hashCode;
  }

  TransactionHistoryModel copyWith({
    int? amount,
    String? date,
    String? id,
    String? referenceId,
    String? time,
    String? type,
  }) {
    return TransactionHistoryModel(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }
}