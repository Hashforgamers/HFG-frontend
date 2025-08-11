class PurchasePassModel {
  final String cafePassId;
  final String paymentId;
  final String paymentMode;

  PurchasePassModel({
    required this.cafePassId,
    required this.paymentId,
    required this.paymentMode,
  });

  factory PurchasePassModel.fromJson(Map<String, dynamic> json) {
    return PurchasePassModel(
      cafePassId: json['cafe_pass_id'],
      paymentId: json['payment_id'],
      paymentMode: json['payment_mode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cafe_pass_id': cafePassId,
      'payment_id': paymentId,
      'payment_mode': paymentMode,
    };
  }
}
