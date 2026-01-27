import 'dart:convert';

class ValidatePassRequest {
  String passUid;
  int vendorId;
  ValidatePassRequest({required this.passUid, required this.vendorId});

  ValidatePassRequest copyWith({String? passUid, int? vendorId}) {
    return ValidatePassRequest(passUid: passUid ?? this.passUid, vendorId: vendorId ?? this.vendorId);
  }

  Map<String, dynamic> toMap() {
    return {'pass_uid': passUid, 'vendor_id': vendorId};
  }

  factory ValidatePassRequest.fromMap(Map<String, dynamic> map) {
    return ValidatePassRequest(passUid: map['pass_uid'] ?? '', vendorId: map['vendor_id']?.toInt() ?? 0);
  }

  String toJson() => json.encode(toMap());

  factory ValidatePassRequest.fromJson(String source) => ValidatePassRequest.fromMap(json.decode(source));

  @override
  String toString() => 'ValidatePassRequest(passUid: $passUid, vendorId: $vendorId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ValidatePassRequest && other.passUid == passUid && other.vendorId == vendorId;
  }

  @override
  int get hashCode => passUid.hashCode ^ vendorId.hashCode;
}
