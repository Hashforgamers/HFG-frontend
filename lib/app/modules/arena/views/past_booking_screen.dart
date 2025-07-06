import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class PastBookingsScreen extends StatefulWidget {
  const PastBookingsScreen({super.key});
  @override
  State<PastBookingsScreen> createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingController ctr = Get.put(BookingController());
  late TabController _tabController;

  String _fmt(String? t) {
    if (t == null) return 'N/A';
    try {
      return DateFormat.jm().format(DateFormat.Hms().parse(t));
    } catch (_) {
      return 'N/A';
    }
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
                child: Text(
                  'My Bookings',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.green,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                    return const Center(
                        child: Text('No past bookings.',
                            style: TextStyle(color: Colors.white)));
                  }
                  // For demo, show all bookings in all tabs
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemCount: ctr.userBookings.length,
                    itemBuilder: (_, i) {
                      final d = ctr.userBookings[i];
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
    this.accessCode, required loc, required double price,
  });

  final String game, cafe, start, end, status;
  final int id;
  final Map<String, dynamic> raw;
  final String? accessCode;

  @override
  Widget build(BuildContext context) {
    final String formattedStatus = status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
        ? w[0].toUpperCase() + w.substring(1).toLowerCase()
        : '')
        .join(' ');

    final String finalAccessCode =
        accessCode ?? (100000 + (id * 173) % 899999).toString();

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
            color: const Color(0xFF181A20),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Left Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$id',
                    style: const TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Booking ID',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Define your scan QR logic here
                      Get.snackbar('QR Scan', 'QR scanner launched');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Scan QR'),
                  ),
                ],
              ),

              const SizedBox(width: 18),
              SizedBox(
                height: 100,
                child: DottedLine(
                  direction: Axis.vertical,
                  dashColor: Colors.white12,
                  dashLength: 4,
                  dashGapLength: 4,
                ),
              ),
              const SizedBox(width: 18),

              // Right Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cafe - $game',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$start - $end',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: $formattedStatus',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    bw.BarcodeWidget(
                      data: 'HASH-$id',
                      barcode: bw.Barcode.code128(),
                      drawText: false,
                      color: Colors.white,
                      width: double.infinity,
                      height: 40,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 16, color: Colors.white38),
                        const SizedBox(width: 6),
                        Text(
                          'Access Code: $finalAccessCode',
                          style: const TextStyle(
                            fontSize: 13,
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
  void reassemble() {              // hot reload fix
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


