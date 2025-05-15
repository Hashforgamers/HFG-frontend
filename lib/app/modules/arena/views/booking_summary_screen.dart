import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:http/http.dart' as http;

import '../../payment/razorpay_controller.dart';
import '../controllers/booking_controller.dart';

class BookingSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> selectedSlots; // Changed type
  final String userName = "Shen"; // Booking user
  final double slotPrice = 50.0; // Price per slot
  final BookingController bookingController = Get.put(BookingController());
  final RazorpayController razorpayController = Get.put(RazorpayController());
  final int gameId;
  final int userId;
  BookingSummaryScreen({Key? key, required this.selectedSlots, required this.gameId,
    required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final razorpayController = Get.put(RazorpayController());

    double totalPrice = calculateTotalPrice();
    print('selectedSlots: ${gameId}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Summary'),
        elevation: 2,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${selectedSlots.length} Slot(s) Selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: selectedSlots.length,
                itemBuilder: (context, index) {
                  final slot = selectedSlots[index];


                  return ListTile(
                    title: Text('PC ${slot['pc_index']}'),
                    subtitle: Text(
                        'Time: ${slot['start_time']} - ${slot['end_time']}'),
                  );
                },
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Booking User', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userName, style: TextStyle(fontSize: 16)),
                trailing: TextButton(
                  onPressed: () {
                    // Change user logic if needed
                  },
                  child: Text('Change', style: TextStyle(color: Colors.orangeAccent)),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              buildPaymentRow('Sub Total', '₹${totalPrice.toStringAsFixed(2)}'),
              buildPaymentRow('GST', '₹0.00'),
              Divider(),
              buildPaymentRow('GRAND TOTAL', '₹${totalPrice.toStringAsFixed(2)}',
                  bold: true, fontSize: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: Color(0xff0F0F0F),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => handleBooking(context,gameId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff00D701),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Obx(() => bookingController.isLoading.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'PROCEED',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleBooking(BuildContext context, int gameId) async {
    if (selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No slots selected!')),
      );
      return;
    }

    double totalPrice = calculateTotalPrice(); // Total amount in rupees
    int amountInPaisa = (totalPrice * 100).toInt(); // Convert amount to paisa

    Set<int> processedSlotIds = {}; // Track processed slot IDs to avoid duplicates

    for (var slot in selectedSlots) {
      int slotId = slot['slot_id'];

      // Skip duplicate slot IDs
      if (processedSlotIds.contains(slotId)) {
        print('Duplicate slot ID detected, skipping: $slotId');
        continue;
      }

      processedSlotIds.add(slotId);

      // Attempt booking for each unique slot ID
      int bookingId = await createBooking(context, gameId, userId, slotId);


      print('Booking successful for Slot ID: $slotId with Booking ID: $bookingId $gameId');
    }

    // If all bookings succeeded, initiate payment
    await initiatePayment(context, amountInPaisa);
  }

  Future<int> createBooking(
      BuildContext context, int gameId, int userId, int slotId) async {
    const String url = "https://hfg-booking-service.onrender.com/api/bookings";

    Map<String, dynamic> payload = {
      "slot_id": slotId,
      "user_id": userId,
      "game_id": gameId,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print(payload);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
         razorpayController.bookingId.value= data['booking_id']; // Ensure this is properly parsed
        return data; // Return the booking ID
      } else {
        print('Failed to create booking for Slot ID: $slotId. Response: ${response.body}');
        return -1; // Indicate failure
      }
    } catch (e) {
      print('Error creating booking for Slot ID: $slotId: $e');
      return -1; // Indicate failure
    }
  }


  Future<void> initiatePayment(BuildContext context, int amountInPaisa) async {
    String receiptId = "order_rcpt_${DateTime.now().millisecondsSinceEpoch}"; // Unique receipt ID

    try {
      // Razorpay API endpoint
      final url = Uri.parse("https://api.razorpay.com/v1/orders");

      // Razorpay credentials (replace with your actual Key ID and Secret)
      String razorpayKeyId = "rzp_test_viVAhwtbVdu1X4";
      String razorpayKeySecret = "PsxakTrbRvfQCbZ1vj2lQ1i5";

      // Base64 encode the credentials
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$razorpayKeyId:$razorpayKeySecret'))}';

      // API request payload
      Map<String, dynamic> payload = {
        "amount": amountInPaisa, // Amount in paisa
        "currency": "INR",
        "receipt": receiptId,
        "payment_capture": 1, // Auto-capture payment
      };

      // Send POST request to Razorpay Order API
      final response = await http.post(
        url,
        headers: {
          "Authorization": basicAuth,
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Order created successfully
        final orderData = jsonDecode(response.body);
        String orderId = orderData['id']; // Extract Razorpay order ID

        // // Show a success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Order created successfully! Order ID: $orderId')),
        // );

        // Trigger Razorpay Checkout
        razorpayController.openCheckout(
          orderId: orderId,
          name: "HashForGamers",
          description: "Booking for selected slots",
          amount: amountInPaisa / 100,
          contact: "9876543210", // Replace with user contact
          email: "user@example.com", // Replace with user email
        );
      } else {
        // Handle error
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['error']?['description'] ?? 'Failed to create order';
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error: $errorMessage')),
        // );
      }
    } catch (e) {
      // Handle exceptions
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
    }
  }

  Widget buildSlotRow(int pcIndex, int timeSlot) {
    return Container(
      decoration: BoxDecoration(
          color: Color(0xff0E0E0E),
          border: Border.all(color: Color(0xff2D2D2D)),
          borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PC $pcIndex', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Sep 17, 2024', style: TextStyle(fontSize: 10)),
                SizedBox(height: 2),
                Text('${getTimeSlot(timeSlot)} - ${getTimeSlot(timeSlot + 1)}',
                    style: TextStyle(fontSize: 10)),
              ],
            ),
            Text('₹$slotPrice', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentRow(String label, String value, {bool bold = false, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value,
          style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  String getTimeSlot(int index) {
    List<String> timeSlots = [
      "12:00 AM",
      "12:30 AM",
      "01:00 AM",
      "01:30 AM",
      "02:00 AM",
      "02:30 AM",
      "03:00 AM",
      "03:30 AM",
    ];
    return timeSlots[index % timeSlots.length];
  }

  Future<void> confirmBooking({required int bookingId, required String paymentId}) async {
    const String url = 'https://hfg-booking-service.onrender.com/api/bookings/confirm';

    final Map<String, dynamic> body = {
      "booking_id": bookingId,
      "payment_id": 1234,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Booking confirmation successful: ${response.body}');
          Get.to(PastBookingsScreen());
      } else {
        print('Failed to confirm booking: ${response.statusCode}, ${response.body}');

      }
    } catch (e) {
      print('Error occurred while confirming booking: $e');
      // Get.snackbar(
      //   'Error',
      //   'Unable to confirm booking. Please try again later.',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    }
  }

  double calculateTotalPrice() {
    return selectedSlots.length * slotPrice;

  }
}
