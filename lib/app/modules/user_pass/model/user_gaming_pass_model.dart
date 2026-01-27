class UserGamingPassModel {
  final int id;
  final String passUid;
  final String passName;
  final int totalHours;
  final double remainingHours;
  final String validFrom;
  final String validTo;
  final bool isActive;
  final bool isGlobal;
  final int vendorId;

  const UserGamingPassModel({
    required this.id,
    required this.passUid,
    required this.passName,
    required this.totalHours,
    required this.remainingHours,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    required this.isGlobal,
    required this.vendorId,
  });

  factory UserGamingPassModel.fromJson(Map<String, dynamic> json) {
    return UserGamingPassModel(
      id: json['id'] ?? 0,
      passUid: json['pass_uid'] ?? '',
      passName: json['pass_name'] ?? '',
      totalHours: json['total_hours'] ?? 0,
      remainingHours: (json['remaining_hours'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['valid_from'] ?? '',
      validTo: json['valid_to'] ?? '',
      isActive: json['is_active'] ?? false,
      isGlobal: json['is_global'] ?? false,
      vendorId: json['vendor_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "pass_uid": passUid,
      "pass_name": passName,
      "total_hours": totalHours,
      "remaining_hours": remainingHours,
      "valid_from": validFrom,
      "valid_to": validTo,
      "is_active": isActive,
      "is_global": isGlobal,
      "vendor_id": vendorId,
    };
  }
}
