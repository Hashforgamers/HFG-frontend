import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class ViewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String endTime;
  final String startTime;
  const ViewDetailScreen(
      {Key? key,
      required this.booking,
      required this.startTime,
      required this.endTime})
      : super(key: key);

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
          hour: int.parse(time.split(':')[0]),
          minute: int.parse(time.split(':')[1]));
      return parsedTime.format(DateTime.now() as BuildContext);
    } catch (e) {
      return 'N/A';
    }
  }

  String formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('dd MMM, yyyy').format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data or use dummy values
    final gameName =
        booking['slot']?['gaming_type_id']?['game_name'] ?? getDummyGameName();
    final status = booking['status'] ?? getDummyStatus();
    final price = booking['slot']?['gaming_type_id']?['single_slot_price'] ??
        getDummyPrice();
    final location = booking['slot']?['location'] ?? getDummyLocation();
    final bookingId = booking['booking_id'] ?? getDummyBookingId();
    final additionalServices =
        booking['additional_services'] ?? getDummyAdditionalServices();
    final cafeName = booking['slot']?['gaming_type_id']?['cafe_name']
            ['cafe_name'] ??
        'Unknown Cafe';
    final accessCode = booking['access_code'];
    final bookDate = booking['book_date'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Booking Details',
            style: GoogleFonts.inter(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cafe Name
            Text(
              cafeName,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.location_solid,
                    size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Booking Details Card
            Card(
              color: const Color(0xFF18191A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14.0), // Reduced from 18.0
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Booking ID',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text('$bookingId',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white)), // Reduced from 16
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text('₹${price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white)), // Reduced from 16
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text(
                          status.toString().capitalizeFirst ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14, // Reduced from 16
                            color:
                                status.toString().toLowerCase() == 'confirmed'
                                    ? Colors.green
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text(formatDate(bookDate),
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white)), // Reduced from 16
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text('$startTime - $endTime',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white)), // Reduced from 16
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Access Code',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54)), // Reduced from 16
                        Text(
                          accessCode ?? '---',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold), // Reduced from 16
                        ),
                      ],
                    ),
                    const Divider(
                        color: Colors.white12, height: 20), // Reduced from 28
                    Text('Additional Services',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54)), // Reduced from 15
                    const SizedBox(height: 4),
                    Text(
                      additionalServices,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white), // Reduced from 15
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14), // Reduced from 18
            // Important Notes Card
            Card(
              color: const Color(0xFF18191A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14.0), // Reduced from 18.0
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Important Notes:',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)), // Reduced from 17
                    const SizedBox(height: 8), // Reduced from 10
                    Text('• Please arrive 15 minutes early.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white60)), // Reduced from 15
                    Text('• Non-refundable booking.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white60)), // Reduced from 15
                    Text('• Contact the venue for any changes to your booking.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white60)), // Reduced from 15
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reduced from 28
            // QR Code
            Center(
              child: QrImageView(
                data:
                    'Booking ID: $bookingId\nGame: $gameName\nLocation: $location\nDate: ${formatDate(bookDate)}\nTime: $startTime - $endTime\nPrice: ₹${price.toStringAsFixed(2)}\nStatus: $status\nAccess Code: ${accessCode ?? '---'}',
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle),
                size: 120.0, // Reduced from 140.0
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 24), // Reduced from 32
            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '#HashforGamers',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2B5726),
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Reduced from 28
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced from 6
                  Text(
                    'For Gamers, By Gamers!',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14), // Reduced from 18
          ],
        ),
      ),
    );
  }
}
