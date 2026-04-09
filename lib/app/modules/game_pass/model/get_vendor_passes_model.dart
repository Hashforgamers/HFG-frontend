import 'dart:convert';

class GetVendorPassesModel {
  final String? id;
  final String? name;
  final double? price;
  final String? passMode;
  final int? totalHour;
  final int? daysValid;
  final String? vendorId;
  final String? hourCalculationMode;
  final int? hoursPerSlot;
  final bool? isActive;
  final String? description;
  final String? sourceGroup;
  GetVendorPassesModel({
    this.id,
    this.name,
    this.price,
    this.passMode,
    this.totalHour,
    this.daysValid,
    this.vendorId,
    this.hourCalculationMode,
    this.hoursPerSlot,
    this.isActive,
    this.description,
    this.sourceGroup,
  });

  factory GetVendorPassesModel.fromMap(
    Map<String, dynamic> map, {
    String? sourceGroup,
  }) {
    double? parsePrice(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
      return null;
    }

    return GetVendorPassesModel(
      id: (map['id'] ?? map['pass_id'] ?? map['cafe_pass_id'] ?? map['_id'])
          ?.toString(),
      name: (map['name'] ?? map['title'] ?? map['pass_name'])?.toString(),
      price: parsePrice(map['price'] ?? map['amount'] ?? map['pass_price']),
      passMode: map['pass_mode']?.toString(),
      totalHour: map['total_hours'] is num
          ? (map['total_hours'] as num).toInt()
          : null,
      daysValid: map['days_valid'] is num
          ? (map['days_valid'] as num).toInt()
          : null,
      vendorId: map['vendor_id']?.toString(),
      hourCalculationMode: map['hour_calculation_mode']?.toString(),
      hoursPerSlot: map['hours_per_slot'] is num
          ? (map['hours_per_slot'] as num).toInt()
          : null,
      isActive: map['is_active'] as bool?,
      description: map['description']?.toString(),
      sourceGroup: sourceGroup,
    );
  }

  factory GetVendorPassesModel.fromJson(String source) =>
      GetVendorPassesModel.fromMap(json.decode(source));
}
