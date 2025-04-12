class Slot {
  final int availableSlot;
  final int gamingTypeId;
  final int id;
  final bool isAvailable;
  final Time time;

  Slot({
    required this.availableSlot,
    required this.gamingTypeId,
    required this.id,
    required this.isAvailable,
    required this.time,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      availableSlot: json['available_slot'],
      gamingTypeId: json['gaming_type_id'],
      id: json['id'],
      isAvailable: json['is_available'],
      time: Time.fromJson(json['time']),
    );
  }
}

class Time {
  final String startTime;
  final String endTime;

  Time({
    required this.startTime,
    required this.endTime,
  });

  factory Time.fromJson(Map<String, dynamic> json) {
    return Time(
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class SlotResponse {
  final bool shopOpen;
  final int slotCount;
  final List<Slot> slots;

  SlotResponse({
    required this.shopOpen,
    required this.slotCount,
    required this.slots,
  });

  factory SlotResponse.fromJson(Map<String, dynamic> json) {
    return SlotResponse(
      shopOpen: json['shop_open'],
      slotCount: json['slot_count'],
      slots: List<Slot>.from(json['slots'].map((slot) => Slot.fromJson(slot))),
    );
  }
}
