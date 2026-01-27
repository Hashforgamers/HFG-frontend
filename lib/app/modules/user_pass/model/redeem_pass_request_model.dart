class RedeemPassRequestModel {
  final int vendorId;
  final int slotId;
  final String? passUid;
  final int bookingId;

  const RedeemPassRequestModel({
    required this.vendorId,
    required this.slotId,
    this.passUid,
    required this.bookingId,
  });

  factory RedeemPassRequestModel.fromJson(Map<String, dynamic> json) {
    return RedeemPassRequestModel(
      vendorId: json["vendor_id"] ?? 0,
      slotId: json["slot_id"] ?? 0,
      passUid: json["pass_uid"],
      bookingId: json["booking_id"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "vendor_id": vendorId,
      "slot_id": slotId,
      "pass_uid": passUid,
      "booking_id": bookingId,
    };
  }
}
