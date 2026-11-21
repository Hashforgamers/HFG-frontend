class PurchasePassModel {
  final String userId;
  final int cafePassId;
  final String paymentId;
  final String paymentMethod;
  PurchasePassModel({required this.userId, required this.cafePassId, required this.paymentId, required this.paymentMethod});

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'cafe_pass_id': cafePassId, 'payment_id': paymentId, 'payment_mode': paymentMethod};
  }
}
