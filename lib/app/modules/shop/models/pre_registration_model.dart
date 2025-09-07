class PreRegistration {
  final String userId;
  final String productId;
  final String productName;
  final double productPrice;
  final DateTime registrationDate;
  final String status;

  PreRegistration({
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.registrationDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status,
    };
  }

  factory PreRegistration.fromMap(Map<String, dynamic> map) {
    return PreRegistration(
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: map['productPrice']?.toDouble() ?? 0.0,
      registrationDate: DateTime.parse(map['registrationDate']),
      status: map['status'] ?? 'pending',
    );
  }
} 