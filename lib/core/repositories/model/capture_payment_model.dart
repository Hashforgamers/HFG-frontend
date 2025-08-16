class CapturePaymentModel {
  String? razorpayPaymentId;
  String? razorpayOrderId;
  String? razorpaySignature;

  CapturePaymentModel({
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
  });

  factory CapturePaymentModel.fromJson(Map<String, dynamic> json) {
    return CapturePaymentModel(
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpayOrderId: json['razorpay_order_id'],
      razorpaySignature: json['razorpay_signature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    };
  }
}
