class GetPassModel {
  final int daysValid;
  final String description;
  final int id;
  final String name;
  final String passType;
  final double price;
  final int vendorId;
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
      daysValid: json['days_valid'],
      description: json['description'],
      id: json['id'],
      name: json['name'],
      passType: json['pass_type'],
      price: json['price'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
    );
  }
}
