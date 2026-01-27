class RedeemPassResponseModel {
  final bool success;
  final String message;
  final RedemptionModel? redemption;
  final String passUid;

  const RedeemPassResponseModel({
    required this.success,
    required this.message,
    required this.redemption,
    required this.passUid,
  });

  factory RedeemPassResponseModel.fromJson(Map<String, dynamic> json) {
    return RedeemPassResponseModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      redemption: json["redemption"] != null
          ? RedemptionModel.fromJson(json["redemption"] as Map<String, dynamic>)
          : null,
      passUid: json["pass_uid"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "redemption": redemption?.toJson(),
      "pass_uid": passUid,
    };
  }
}

class RedemptionModel {
  final int id;
  final double hoursDeducted;
  final double remainingHours;

  const RedemptionModel({
    required this.id,
    required this.hoursDeducted,
    required this.remainingHours,
  });

  factory RedemptionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionModel(
      id: json["id"] ?? 0,
      hoursDeducted: (json["hours_deducted"] as num?)?.toDouble() ?? 0.0,
      remainingHours: (json["remaining_hours"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "hours_deducted": hoursDeducted,
      "remaining_hours": remainingHours,
    };
  }
}
