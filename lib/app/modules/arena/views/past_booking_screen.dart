import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PastBookingsScreen extends StatefulWidget {

  PastBookingsScreen({Key? key}) : super(key: key);

  @override
  State<PastBookingsScreen> createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen> {
  final BookingController bookingController = Get.put(BookingController());

  String formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final parsedTime = DateFormat.Hms().parse(time);
      return DateFormat.jm().format(parsedTime); // Converts to 12-hour format
    } catch (e) {
      return 'N/A';
    }
  }

  // Dummy data methods
  String getDummyGameName() => 'Unknown Game';

  String getDummyTime() => 'N/A';

  String getDummyStatus() => 'Pending';

  String getDummyLocation() => 'Mumbai';

  double getDummyPrice() => 0.0;

  int getDummyBookingId() => 9999;

  String getDummyAdditionalServices() => 'Snacks included. Complimentary drinks.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookingController.fetchUserBookings();
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Past Bookings'),
        backgroundColor: Colors.black,
      ),
      body: Obx(() {
        if (bookingController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (bookingController.userBookings.isEmpty) {
          return Center(
            child: Text(
              'No past bookings found.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: bookingController.userBookings.length,
          itemBuilder: (context, index) {
            final booking = bookingController.userBookings[index];

            // Extract or use dummy values for missing data
            final gameName = booking['slot']?['gaming_type_id']?['game_name'] ?? getDummyGameName();
            final startTime = formatTime(booking['slot']?['time']?['start_time']) ?? getDummyTime();
            final endTime = formatTime(booking['slot']?['time']?['end_time']) ?? getDummyTime();
            final status = booking['status'] ?? getDummyStatus();
            final price = booking['slot']?['gaming_type_id']?['single_slot_price'] ?? getDummyPrice();
            final location = booking['slot']?['location'] ?? getDummyLocation();
            final bookingId = booking['booking_id'] ?? getDummyBookingId();
            final additionalServices = booking['additional_services'] ?? getDummyAdditionalServices();
            final cafeName = booking['slot']?['gaming_type_id']?['cafe_name']['cafe_name'] ?? 'Unknown Cafe';

            return BookingCard(
              gameName: gameName,
              cafeName: cafeName,
              startTime: startTime,
              endTime: endTime,
              status: status,
              price: double.parse('$price'),
              location: location,
              bookingId: bookingId,
              additionalServices: additionalServices,
              booking: booking,
            );
          },
        );
      }),
    );
  }
}

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
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    required this.location,
    required this.bookingId,
    required this.additionalServices,
    required this.booking,
    required this.cafeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Color(0xff1A1A1A),
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(margin: EdgeInsets.only(top: 5),
                        child: Column(mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                cafeName.toUpperCase() ,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff00D701),),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(CupertinoIcons.location_circle,size: 12,),
                                SizedBox(width: 3,),
                                Text(
                                  location,
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '$startTime ----- ',
                                  style: GoogleFonts.tulpenOne(fontSize: 26 , color: Colors.white,),
                                ),
                                Image.asset('assets/game-controller.png',scale: 15,color: Colors.white,),
                                Text(
                                    ' ----- $endTime',
                                    style: GoogleFonts.tulpenOne(fontSize: 26, color: Colors.white,)
                                ),
                              ],
                            ),
                            Divider(color: Colors.white24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'BOOKING ID',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                                Text(
                                  '$bookingId',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.yellow),
                                ),
                              ],
                            ),
                            Row(                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                Text(
                                  'AMOUNT',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                                Text(
                                  '₹${price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff00D701),),
                                ),
                              ],
                            ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     Text(
                            //       'STATUS',
                            //       style: TextStyle(fontSize: 12, color: Colors.white),
                            //     ),
                            //     Text(
                            //       status,
                            //       style: TextStyle(
                            //         fontSize: 12,
                            //         fontWeight: FontWeight.bold,
                            //         color: status == 'confirmed' ? Colors.green : Colors.orange,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            Divider(color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),


                    Stack(
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

                  ],
                ),
              ),



              SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: Get.width*0.45,
                    child: Text(
                      '* Please arrive 15 minutes early.\n'
                          '* Non-refundable booking.\n'
                          '* Contact the venue for any changes to your booking.',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => ViewDetailScreen(booking: booking,
                        startTime:startTime,
                          endTime:endTime
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xff00D701),
                        onPrimary: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
