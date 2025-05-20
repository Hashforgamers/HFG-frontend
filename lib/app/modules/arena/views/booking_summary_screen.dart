import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import '../../payment/razorpay_controller.dart';
import '../controllers/booking_controller.dart';

class BookingSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> selectedSlots;
  final int gameId;
  final int userId;

  BookingSummaryScreen({Key? key, required this.selectedSlots, required this.gameId, required this.userId}) : super(key: key);

  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());

  final String userName = "Shen";
  final double slotPrice = 50.0;

  @override
  Widget build(BuildContext context) {
    double totalPrice = calculateTotalPrice();

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text('Booking Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${selectedSlots.length} Slot(s) Selected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: selectedSlots.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey.shade800),
                itemBuilder: (context, index) {
                  final slot = selectedSlots[index];
                  return ListTile(
                    tileColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text('PC ${slot['pc_index']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Time: ${slot['start_time']} - ${slot['end_time']}', style: TextStyle(color: Colors.white70)),
                  );
                },
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking User', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70)),
                      SizedBox(height: 4),
                      Text(userName, style: TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  TextButton(onPressed: () {}, child: Text('Change', style: TextStyle(color: Colors.deepOrange)))
                ],
              ),
              Divider(height: 32, color: Colors.grey.shade800),
              Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              SizedBox(height: 12),
              buildPaymentRow('Sub Total', '₹${totalPrice.toStringAsFixed(2)}'),
              buildPaymentRow('GST', '₹0.00'),
              Divider(color: Colors.grey.shade800),
              buildPaymentRow('GRAND TOTAL', '₹${totalPrice.toStringAsFixed(2)}', bold: true, fontSize: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF0F0F0F),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => handleBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffDE3A3A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Obx(() => bookingController.isLoading.value
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('PROCEED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleBooking(BuildContext context) async {
    if (selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No slots selected!')),
      );
      return;
    }

    double totalPrice = calculateTotalPrice();
    int amountInPaisa = (totalPrice * 100).toInt();

    List<int> slotIds = selectedSlots.map((slot) => slot['slot_id'] as int).toList();
    List<int> bookingIds = await createBooking(slotIds);
    print(slotIds);
    if (bookingIds.isEmpty) {
      print("Booking failed.");
      return;
    }

    razorpayController.bookingIdList.value = bookingIds;
    await initiatePayment(context, amountInPaisa);
  }

  Future<List<int>> createBooking(List<int> slotIds) async {
    const String url = "https://hfg-booking-hmnx.onrender.com/api/bookings";
    final today = DateTime.now();
    final bookDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final payload = {
      "slot_id": slotIds,
      "user_id": userId,
      "game_id": gameId,
      "book_date": bookDate
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<int>.from(data['booking_ids']);
      } else {
        print('Failed to create booking. Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception during booking: $e');
      return [];
    }
  }

  Future<void> initiatePayment(BuildContext context, int amountInPaisa) async {
    String receiptId = "order_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = Uri.parse("https://api.razorpay.com/v1/orders");
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('rzp_test_viVAhwtbVdu1X4:PsxakTrbRvfQCbZ1vj2lQ1i5'));

    Map<String, dynamic> payload = {
      "amount": amountInPaisa,
      "currency": "INR",
      "receipt": receiptId,
      "payment_capture": 1,
    };

    try {
      final response = await http.post(url, headers: {"Authorization": basicAuth, "Content-Type": "application/json"}, body: jsonEncode(payload));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        razorpayController.openCheckout(
          orderId: data['id'],
          name: "HashForGamers",
          description: "Booking for selected slots",
          amount: amountInPaisa / 100,
          contact: "9876543210",
          email: "user@example.com",
        );
      } else {
        print('Error creating Razorpay order: ${response.body}');
      }
    } catch (e) {
      print('Payment error: $e');
    }
  }

  Widget buildPaymentRow(String label, String value, {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
        ],
      ),
    );
  }

  double calculateTotalPrice() => selectedSlots.length * slotPrice;
}