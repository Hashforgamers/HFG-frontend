import 'dart:convert';

class GetVendorPassesModel {
  final String? id;
  final String? name;
  final int? price;
  final String? passMode;
  final int? totalHour;
  final int? daysValid;
  final String? vendorId;
  final String? hourCalculationMode;
  final int? hoursPerSlot;
  final bool? isActive;
  final String? description;
  GetVendorPassesModel({this.id, this.name, this.price, this.passMode, this.totalHour, this.daysValid, this.vendorId, this.hourCalculationMode, this.hoursPerSlot, this.isActive, this.description});

  factory GetVendorPassesModel.fromMap(Map<String, dynamic> map) {
    return GetVendorPassesModel(
      id: map['id'],
      name: map['name'],
      price: map['price']?.toInt(),
      passMode: map['pass_mode'],
      totalHour: map['total_hours']?.toInt(),
      daysValid: map['days_valid']?.toInt(),
      vendorId: map['vendor_id'],
      hourCalculationMode: map['hour_calculation_mode'],
      hoursPerSlot: map['hours_per_slot']?.toInt(),
      isActive: map['is_active'],
      description: map['description'],
    );
  }

  factory GetVendorPassesModel.fromJson(String source) => GetVendorPassesModel.fromMap(json.decode(source));
}
