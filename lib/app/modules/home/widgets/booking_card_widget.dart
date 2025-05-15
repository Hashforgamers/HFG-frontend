import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../utils/widgets/vertical_dotted_line.dart';
import '../../arena/views/past_booking_screen_detail.dart';

class BookingCard extends StatelessWidget {
  final String gameName;
  final String cafeName;
  final String startTime;
  final String endTime;
  final String status;
  final double price;
  final String location;
  final int bookingId;
  final String additionalServices;
  final Map<String, dynamic> booking;

  const BookingCard({
    Key? key,
    required this.gameName,
    required this.cafeName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    required this.location,
    required this.bookingId,
    required this.additionalServices,
    required this.booking,
  }) : super(key: key);

  void _showQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensures the dialog doesn't take unnecessary space
            children: [
              Text(
                'Booking QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),
              // Ensure QrImageView has proper constraints
              SizedBox(
                width: 200, // Set width for QR code
                height: 200, // Set height for QR code
                child: QrImageView(
                  data:
                  'Booking ID: $bookingId\nGame: $gameName\nLocation: $location\nTime: $startTime - $endTime\nPrice: ₹${price.toStringAsFixed(2)}\nStatus: $status',
                  version: QrVersions.auto,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ViewDetailScreen(booking: booking,startTime: startTime,endTime: endTime,));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        height: 80,
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: Color(0xff1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cafeName.toUpperCase(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff00D701)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '$startTime ----- ',
                              style: GoogleFonts.tulpenOne(fontSize: 38, color: Colors.white,),
                            ),
                            Image.asset('assets/game-controller.png',scale: 15,color: Colors.white,),
                            Text(
                                ' ----- $endTime',
                                style: GoogleFonts.tulpenOne(fontSize: 38, color: Colors.white,)
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                  DottedVerticalDivider(
                    height: 70,
                    dotSize: 1,
                    spacing: 3,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 15,),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Get.to(() => ViewDetailScreen(booking: booking,startTime: startTime,endTime: endTime,)),
                        child: Container(
                          width: 80, // Set fixed width
                          padding: EdgeInsets.symmetric(vertical: 8), // Padding for height
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'VIEW DETAILS',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10), // Spacing between buttons
                      GestureDetector(
                        onTap: () => _showQrCode(context),
                        child: Container(
                          width: 80, // Same width as the first button
                          padding: EdgeInsets.symmetric(vertical: 8), // Padding for height
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'SHOW QR',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )


                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
