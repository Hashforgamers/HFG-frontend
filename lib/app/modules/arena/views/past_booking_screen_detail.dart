import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // startTime = startTime?? getDummyTime();
    // final endTime = formatTime(booking['slot']?['time']?['end_time']) ?? getDummyTime();
    final status = booking['status'] ?? getDummyStatus();
    final price = booking['slot']?['gaming_type_id']?['single_slot_price'] ?? getDummyPrice();
    final location = booking['slot']?['location'] ?? getDummyLocation();
    final bookingId = booking['booking_id'] ?? getDummyBookingId();
    final additionalServices = booking['additional_services'] ?? getDummyAdditionalServices();
    final cafeName = booking['slot']?['gaming_type_id']?['cafe_name']['cafe_name'] ?? 'Unknown Cafe';

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Container(height: Get.height*0.99,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game and Booking Details
              Text(
                cafeName.toUpperCase() ,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xffDE3A3A),),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.location_circle,size: 16,),
                  SizedBox(width: 3,),
                  Text(
                    location,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$startTime ----- ',
                    style: GoogleFonts.tulpenOne(fontSize: 56 , color: Colors.white,),
                  ),
                  Image.asset('assets/game-controller.png',scale: 15,color: Colors.white,),
                  Text(
                      ' ----- $endTime',
                      style: GoogleFonts.tulpenOne(fontSize: 56, color: Colors.white,)
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(color: Colors.white24),

              // Booking ID and Price
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking ID',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    Text(
                      '$bookingId',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),

              // Status
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: status == 'confirmed' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(color: Colors.white24),

              // Additional Services
              Text(
                'Additional Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                additionalServices,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 16),
              Divider(color: Colors.white24),

              // QR Code
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      padding: EdgeInsets.only(left: 15, top: 5, right: 2),
                      data:
                      'Booking ID: $bookingId\nGame: $gameName\nLocation: $location\nTime: $startTime - $endTime\nPrice: ₹${price.toStringAsFixed(2)}\nStatus: $status',
                      version: QrVersions.auto,
                      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle),
                      size: 150.0,
                      foregroundColor: Colors.white,
                    ),
                    Container(color: Colors.black,
                      margin: EdgeInsets.only(left: 14,bottom: 5),
                      padding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
                      child: Text(
                        'HASH', // Text to display in the center
                        style: TextStyle(
                          color: Colors.white, // Adjust text color to contrast with the QR code
                          fontSize: 16, // Adjust text size
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Notes
              Text(
                'Important Notes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                '• Please arrive 15 minutes early.\n'
                    '• Non-refundable booking.\n'
                    '• Contact the venue for any changes to your booking.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
