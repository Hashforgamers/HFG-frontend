import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'dart:convert';

class PastBookingsScreen extends StatefulWidget {
  const PastBookingsScreen({super.key});
  @override
  State<PastBookingsScreen> createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingController ctr = Get.put(BookingController());
  late TabController _tabController;
  String _sortOrder = 'newer'; // 'newer' or 'older'

  String _fmt(String? t) {
    if (t == null) return 'N/A';
    try {
      return DateFormat.jm().format(DateFormat.Hms().parse(t));
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('dd MMM, yyyy').format(parsedDate);
    } catch (_) {
      return 'N/A';
    }
  }

  List<Map<String, dynamic>> _getSortedBookings() {
    final bookings = List<Map<String, dynamic>>.from(ctr.userBookings);

    // Filter to only show bookings with status 'confirmed' or 'extra'
    final filteredBookings = bookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return status == 'confirmed' || status == 'extra';
    }).toList();

    // Sort by booking ID (assuming higher ID = newer booking)
    if (_sortOrder == 'newer') {
      filteredBookings.sort(
          (a, b) => (b['booking_id'] ?? 0).compareTo(a['booking_id'] ?? 0));
    } else {
      filteredBookings.sort(
          (a, b) => (a['booking_id'] ?? 0).compareTo(b['booking_id'] ?? 0));
    }

    return filteredBookings;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ctr.fetchUserBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Bookings',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    // Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        // color: const Color(0xFF18191A),
                      ),
                      child: DropdownButton<String>(
                        value: _sortOrder,
                        dropdownColor: const Color(0xFF18191A),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.green, size: 20),
                        items:  [
                          DropdownMenuItem(
                            value: 'newer',
                            child: Text('Newer First',
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 'older',
                            child: Text('Older First',
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortOrder = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 8),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8),
              //   child: TabBar(
              //     controller: _tabController,
              //     indicatorColor: Colors.transparent,
              //     labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              //     labelColor: const Color(0xff338125),
              //     unselectedLabelColor: Colors.white70,
              //     labelStyle: const TextStyle(
              //         fontWeight: FontWeight.bold, fontSize: 18),
              //     unselectedLabelStyle: const TextStyle(
              //         fontWeight: FontWeight.w500, fontSize: 18),
              //     tabs: const [
              //       Tab(child: Text('All',style: TextStyle(color: Colors.green),)),
              //       Tab(child: Text('Upcoming',style: TextStyle(color: Colors.green),)),
              //       Tab(child: Text('Completed',style: TextStyle(color: Colors.green),)),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  if (ctr.isLoading.value) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (ctr.userBookings.isEmpty) {
                    return Center(
                        child: Text('No past bookings.',
                            style: GoogleFonts.inter(color: Colors.white)));
                  }

                  final sortedBookings = _getSortedBookings();

                  // For demo, show all bookings in all tabs
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemCount: sortedBookings.length,
                    itemBuilder: (_, i) {
                      final d = sortedBookings[i];
                      return BookingTicketCard(
                        game: d['slot']?['gaming_type_id']?['game_name'] ??
                            'Unknown',
                        cafe: d['slot']?['gaming_type_id']?['cafe_name']
                                ['cafe_name'] ??
                            'Cafe',
                        start: _fmt(d['slot']?['time']?['start_time']),
                        end: _fmt(d['slot']?['time']?['end_time']),
                        status: d['status'] ?? 'Pending',
                        price: double.tryParse(
                                '${d['slot']?['gaming_type_id']?['single_slot_price'] ?? 0}') ??
                            0,
                        loc: d['slot']?['location'] ?? 'Mumbai',
                        id: d['booking_id'] ?? 0,
                        raw: d,
                        accessCode: d['access_code'],
                        bookDate: d['book_date'],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      );
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 18.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height / 2 - notchRadius);
    path.arcToPoint(
      Offset(0, size.height / 2 + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2 + notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BookingTicketCard extends StatelessWidget {
  const BookingTicketCard({
    super.key,
    required this.game,
    required this.cafe,
    required this.start,
    required this.end,
    required this.status,
    required this.id,
    required this.raw,
    required this.loc,
    required this.price,
    this.accessCode,
    this.bookDate,
  });

  final String game, cafe, start, end, status, loc;
  final int id;
  final double price;
  final Map<String, dynamic> raw;
  final String? accessCode;
  final String? bookDate;

  void _handleScannedCode(String scannedCode) async {
    try {
      // Parse the JSON from the QR code
      final Map<String, dynamic> qrData = jsonDecode(scannedCode);

      // Extract the required fields from the QR code JSON
      final consoleId = qrData['console_id']?.toString() ?? '';
      final gameId = qrData['game_id']?.toString() ?? '';
      final vendorId = qrData['vendor_id']?.toString() ?? '';
      final bookingId = id.toString();

      // Validate that all required fields are present
      if (consoleId.isEmpty || gameId.isEmpty || vendorId.isEmpty) {
        Get.snackbar(
          'Error',
          'Invalid QR Code format. Missing required fields.',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Call the scanQrCode API with the parsed data
      final remoteRepo = locator<RemoteRepoInterface>();
      final result = await remoteRepo.scanQrCode(
        consoleId: consoleId,
        gameId: gameId,
        vendorId: vendorId,
        bookingId: bookingId,
      );

      Get.snackbar(
        'Success',
        result, // Use the API response message
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      String errorMessage = 'Failed to process QR code';

      if (e is FormatException) {
        errorMessage = 'Invalid QR Code format. Please scan a valid QR code.';
      } else {
        errorMessage = 'Failed to verify booking: ${e.toString()}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedStatus = status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1).toLowerCase()
            : '')
        .join(' ');

    // Handle access code display - show "---" if null
    final String displayAccessCode = accessCode ?? '---';

    // Format the booking date
    String formattedDate = 'N/A';
    if (bookDate != null) {
      try {
        final parsedDate = DateFormat('yyyy-MM-dd').parse(bookDate!);
        formattedDate = DateFormat('dd MMM, yyyy').format(parsedDate);
      } catch (_) {
        formattedDate = 'N/A';
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Get.to(() => ViewDetailScreen(
            booking: raw,
            startTime: start,
            endTime: end,
          )),
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
              width: 25,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$id',
                            style:  GoogleFonts.inter(
                              color: Color(0xFF338125),
                              fontSize: 24, // Reduced from 28
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                    'Booking ID',
                    style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10, // Reduced from 12
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Get.to(() => const QrScannerView());
                              if (result != null) {
                                _handleScannedCode(result.toString());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF338125),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // very slim
                              minimumSize: const Size(0, 28), // optional: control height
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(4),
                              ),
                              textStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // avoid extra height
                              elevation: 0, // optional: keep it flat
                            ),
                            child: const Text('Scan QR'),
                          ),

                        ],
                      ),

              const SizedBox(width: 12), // Reduced from 18
              SizedBox(
                height: 80, // Reduced from 100
                child: DottedLine(
                  direction: Axis.vertical,
                  dashColor: Colors.white12,
                  dashLength: 3, // Reduced from 4
                  dashGapLength: 3, // Reduced from 4
                ),
              ),
              const SizedBox(width: 12), // Reduced from 18

                      // Right Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$cafe - $game',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Reduced from 16
                              ),
                            ),
                            const SizedBox(height: 4), // Reduced from 6
                            Text(
                              '$start - $end',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 11, // Reduced from 13
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: $formattedDate',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 11, // Reduced from 13
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Status: $formattedStatus',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 11, // Reduced from 13
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced from 12
                            bw.BarcodeWidget(
                              data: 'HASH-$id',
                              barcode: bw.Barcode.code128(),
                              drawText: false,
                              color: Colors.white,
                              width: double.infinity,
                              height: 30, // Reduced from 40
                            ),
                            const SizedBox(height: 6), // Reduced from 8
                            Row(
                              children: [
                                const Icon(Icons.lock_outline,
                                    size: 14, color: Colors.white38), // Reduced from 16
                                const SizedBox(width: 4), // Reduced from 6
                                Text(
                                  'Access Code: $displayAccessCode',
                                  style: GoogleFonts.inter(
                                    fontSize: 11, // Reduced from 13
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Left Section

              Container(
                width: 25,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*────────────────────  Ticket-style clipper  ────────────────────*/

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 20;

    final Path path = Path();
    path.moveTo(0, 0);

    // Left edge to top-notch start
    path.lineTo(0, size.height / 2 - radius);
    path.arcToPoint(
      Offset(0, size.height / 2 + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );

    // Bottom-left to bottom
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);

    // Right edge to bottom-notch start
    path.lineTo(size.width, size.height / 2 + radius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );

    // Top-right to top
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// qr_scanner_view.dart

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});
  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    // hot reload fix
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: Get.width * 0.7,
            ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController c) {
    controller = c;
    c.scannedDataStream.listen((scanData) {
      controller?.pauseCamera();
      Get.back(result: scanData.code); // return the scanned content
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
