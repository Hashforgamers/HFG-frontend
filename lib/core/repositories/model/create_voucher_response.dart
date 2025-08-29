class CreateVoucherResponse {
  final int hashCoinsRemaining;
  final String message;
  final String voucherCode;

  CreateVoucherResponse({
    required this.hashCoinsRemaining,
    required this.message,
    required this.voucherCode,
  });

  factory CreateVoucherResponse.fromJson(Map<String, dynamic> json) {
    return CreateVoucherResponse(
      hashCoinsRemaining: json['hash_coins_remaining'] ?? 0,
      message: json['message'] ?? '',
      voucherCode: json['voucher_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash_coins_remaining': hashCoinsRemaining,
      'message': message,
      'voucher_code': voucherCode,
    };
  }

  @override
  String toString() {
    return 'CreateVoucherResponse(hashCoinsRemaining: $hashCoinsRemaining, message: $message, voucherCode: $voucherCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateVoucherResponse &&
        other.hashCoinsRemaining == hashCoinsRemaining &&
        other.message == message &&
        other.voucherCode == voucherCode;
  }

  @override
  int get hashCode {
    return hashCoinsRemaining.hashCode ^
        message.hashCode ^
        voucherCode.hashCode;
  }
}

