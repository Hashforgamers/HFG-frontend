import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String endTime;
  final String startTime;
  const ViewDetailScreen({Key? key, required this.booking, required this.startTime, required this.endTime}) : super(key: key);

  // Dummy value methods for missing data
  String getDummyGameName() => 'Unknown Game';
  String getDummyTime() => 'N/A';
  String getDummyStatus() => 'Pending';
  String getDummyLocation() => 'Not Available';
  double getDummyPrice() => 0.0;
  int getDummyBookingId() => 9999;
  String getDummyAdditionalServices() => 'No additional services provided.';

  String formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final parsedTime = TimeOfDay(
          hour: int.parse(time.split(':')[0]), minute: int.parse(time.split(':')[1]));
      return parsedTime.format(DateTime.now() as BuildContext);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data or use dummy values
    final gameName = booking['slot']?['gaming_type_id']?['game_name'] ?? getDummyGameName();
    final status = booking['status'] ?? getDummyStatus();
    final price = booking['slot']?['gaming_type_id']?['single_slot_price'] ?? getDummyPrice();
    final location = booking['slot']?['location'] ?? getDummyLocation();
    final bookingId = booking['booking_id'] ?? getDummyBookingId();
    final additionalServices = booking['additional_services'] ?? getDummyAdditionalServices();
    final cafeName = booking['slot']?['gaming_type_id']?['cafe_name']['cafe_name'] ?? 'Unknown Cafe';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Booking Details', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cafe Name
            Text(
              cafeName,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(CupertinoIcons.location_solid, size: 18, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 18),
            // Booking Details Card
            Card(
              color: Color(0xFF18191A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Booking ID', style: TextStyle(fontSize: 16, color: Colors.white54)),
                        Text('$bookingId', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price', style: TextStyle(fontSize: 16, color: Colors.white54)),
                        Text('₹${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status', style: TextStyle(fontSize: 16, color: Colors.white54)),
                        Text(
                          status.toString().capitalizeFirst ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: status.toString().toLowerCase() == 'confirmed' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time', style: TextStyle(fontSize: 16, color: Colors.white54)),
                        Text('$startTime - $endTime', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    Divider(color: Colors.white12, height: 28),
                    Text('Additional Services', style: TextStyle(fontSize: 15, color: Colors.white54)),
                    SizedBox(height: 4),
                    Text(
                      additionalServices,
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18),
            // Important Notes Card
            Card(
              color: Color(0xFF18191A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Important Notes:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 10),
                    Text('• Please arrive 15 minutes early.', style: TextStyle(fontSize: 15, color: Colors.white60)),
                    Text('• Non-refundable booking.', style: TextStyle(fontSize: 15, color: Colors.white60)),
                    Text('• Contact the venue for any changes to your booking.', style: TextStyle(fontSize: 15, color: Colors.white60)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 28),
            // QR Code
            Center(
              child: QrImageView(
                data: 'Booking ID: $bookingId\nGame: $gameName\nLocation: $location\nTime: $startTime - $endTime\nPrice: ₹${price.toStringAsFixed(2)}\nStatus: $status',
                version: QrVersions.auto,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle),
                size: 140.0,
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
            ),
            SizedBox(height: 32),
            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '#HashforGamers',
                    style: TextStyle(
                      color: Color(0xFF2B5726),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For Gamers, By Gamers!',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
