class GetPassModel {
  final int daysValid;
  final String description;
  final String id;
  final String name;
  final String passType;
  final double price;
  final String vendorId;
  final String vendorName;

  GetPassModel({
    required this.daysValid,
    required this.description,
    required this.id,
    required this.name,
    required this.passType,
    required this.price,
    required this.vendorId,
    required this.vendorName,
  });

  factory GetPassModel.fromJson(Map<String, dynamic> json) {
    return GetPassModel(
      daysValid: (json['days_valid'] as num).toInt(),
      description: (json['description'] ?? '').toString(),
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      passType: (json['pass_type'] ?? '').toString(),
      price: (json['price'] as num).toDouble(),
      vendorId: json['vendor_id'].toString(),
      vendorName: (json['vendor_name'] ?? '').toString(),
    );
  }
}
