class BookingModel {
  final int slotId;
  final int bookingId;
  final String bookDate;

  BookingModel({
    required this.slotId,
    required this.bookingId,
    required this.bookDate,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      slotId: json['slot_id'],
      bookingId: json['booking_id'],
      bookDate: json['book_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_id': slotId,
      'booking_id': bookingId,
      'book_date': bookDate,
    };
  }
}
