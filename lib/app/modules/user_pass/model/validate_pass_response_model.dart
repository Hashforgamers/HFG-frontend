class ValidatePassResponseModel {
  final bool valid;
  final PassModel? pass;

  const ValidatePassResponseModel({
    required this.valid,
    required this.pass,
  });

  factory ValidatePassResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidatePassResponseModel(
      valid: json["valid"] ?? false,
      pass: json["pass"] != null
          ? PassModel.fromJson(json["pass"] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "valid": valid,
      "pass": pass?.toJson(),
    };
  }
}

class PassModel {
  final String passUid;
  final String passName;
  final double remainingHours;
  final int totalHours;
  final String validTo;
  final bool isGlobal;
  final String hourCalculationMode;

  const PassModel({
    required this.passUid,
    required this.passName,
    required this.remainingHours,
    required this.totalHours,
    required this.validTo,
    required this.isGlobal,
    required this.hourCalculationMode,
  });

  factory PassModel.fromJson(Map<String, dynamic> json) {
    return PassModel(
      passUid: json["pass_uid"] ?? "",
      passName: json["pass_name"] ?? "",
      remainingHours: (json["remaining_hours"] as num?)?.toDouble() ?? 0.0,
      totalHours: json["total_hours"] ?? 0,
      validTo: json["valid_to"] ?? "",
      isGlobal: json["is_global"] ?? false,
      hourCalculationMode: json["hour_calculation_mode"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "pass_uid": passUid,
      "pass_name": passName,
      "remaining_hours": remainingHours,
      "total_hours": totalHours,
      "valid_to": validTo,
      "is_global": isGlobal,
      "hour_calculation_mode": hourCalculationMode,
    };
  }
}
