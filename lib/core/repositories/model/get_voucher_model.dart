class GetVoucherModel {
  final List<Voucher> vouchers;

  GetVoucherModel({required this.vouchers});

  factory GetVoucherModel.fromJson(Map<String, dynamic> json) {
    return GetVoucherModel(
      vouchers: (json['vouchers'] as List)
          .map((voucher) => Voucher.fromJson(voucher))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vouchers': vouchers.map((voucher) => voucher.toJson()).toList(),
    };
  }
}

class Voucher {
  final String code;
  final String createdAt;
  final int discountPercentage;
  final int id;
  final bool isActive;
  final int userId;

  Voucher({
    required this.code,
    required this.createdAt,
    required this.discountPercentage,
    required this.id,
    required this.isActive,
    required this.userId,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: json['code'] ?? '',
      createdAt: json['created_at'] ?? '',
      discountPercentage: json['discount_percentage'] ?? 0,
      id: json['id'] ?? 0,
      isActive: json['is_active'] ?? false,
      userId: json['user_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'created_at': createdAt,
      'discount_percentage': discountPercentage,
      'id': id,
      'is_active': isActive,
      'user_id': userId,
    };
  }

  @override
  String toString() {
    return 'Voucher(code: $code, createdAt: $createdAt, discountPercentage: $discountPercentage, id: $id, isActive: $isActive, userId: $userId)';
  }
}