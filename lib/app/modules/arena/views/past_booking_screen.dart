import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../utils/widgets/loader.dart';

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
  final prefs = locator<SharedPreferences>();
  bool hasRated = false;

  void getRatingBool(){
    final hasRated = prefs.getBool('hasRatedApp') ?? false;
    this.hasRated = hasRated;
  }

  @override
  void initState() {
    super.initState();
    getRatingBool();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctr.fetchUserBookings().then((_){
        if(!hasRated && ctr.userBookings.isNotEmpty){
          _maybeShowRatingDialogIfPending();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(String? t) {
    if (t == null) return 'N/A';
    try {
      return DateFormat.jm().format(DateFormat.Hms().parse(t));
    } catch (_) {
      return 'N/A';
    }
  }

// Colors
  static const _green = Color(0xff00DC00);
  static const _yellow = Color(0xFFF5C042);
  static const _red = Color(0xFFE2584E);

// Bucketing stays as you wrote (with pending_verified excluded)
  String _statusBucket(dynamic rawStatus) {
    final s = (rawStatus ?? '').toString().toLowerCase().trim();
    if (s.isEmpty) return 'pending';
    if (s.contains('pending_verified')) return 'exclude';
    if (s.contains('confirm') || s.contains('success')) return 'confirmed';
    if (s.contains('pend') || s.contains('await') || s.contains('unpaid')) return 'pending';
    return 'pending';
  }

// Count per bucket for tab badges
  int _countFor(String filter) {
    return ctr.userBookings.where((b) {
      final bucket = _statusBucket(b['status']);
      if (bucket == 'exclude') return false;
      if (filter == 'all') return true;
      return bucket == filter;
    }).length;
  }


  List<Map<String, dynamic>> _getFilteredAndSorted(String filter) {
    final bookings = List<Map<String, dynamic>>.from(ctr.userBookings);

    final filtered = bookings.where((b) {
      final bucket = _statusBucket(b['status']);
      if (bucket == 'exclude') return false; // 🚫 skip
      if (filter == 'all') return true;
      return bucket == filter;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final aId = (a['booking_id'] ?? 0) as int;
      final bId = (b['booking_id'] ?? 0) as int;
      return _sortOrder == 'newer' ? bId.compareTo(aId) : aId.compareTo(bId);
    });

    return filtered;
  }

  void _maybeShowRatingDialogIfPending() {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xff404040),
              title: const Text(
                  "Enjoying our app?", style: TextStyle(color: Colors.white)),
              content: const Text(
                  "We’d love your feedback! Please rate us on the Play Store.",
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // "Maybe later" – do NOT set hasRatedApp
                    // Next successful payment will set ratePromptPending again.
                  },
                  child: const Text(
                      "Maybe Later", style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await prefs.setBool(
                        'hasRatedApp', true); // never show again
                    final InAppReview inAppReview = InAppReview.instance;
                    await inAppReview.openStoreListing();
                  },
                  child: const Text(
                      "Rate Us", style: TextStyle(color: const Color(0xff00DC00))),
                ),
              ],
            );
          },
        );
      }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xff404040),
          title: const Text("Enjoying our app?", style: TextStyle(color: Colors.white)),
          content: const Text("We’d love your feedback! Please rate us on the Play Store.",
              style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // "Maybe later" – do NOT set hasRatedApp
                // Next successful payment will set ratePromptPending again.
              },
              child: const Text("Maybe Later", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasRatedApp', true);        // never show again
                await prefs.setBool('ratePromptPending', false); // extra safety
                final InAppReview inAppReview = InAppReview.instance;
                await inAppReview.openStoreListing();
              },
              child: const Text("Rate Us", style: TextStyle(color: const Color(0xff00DC00))),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Bookings',
                    style:
                    GoogleFonts.inter(fontSize: 18, color: Colors.white)),
                IconButton(
                  splashRadius: 18,
                  tooltip:
                  _sortOrder == 'newer' ? 'Newest first' : 'Oldest first',
                  onPressed: () {
                    setState(() {
                      _sortOrder =
                      _sortOrder == 'newer' ? 'older' : 'newer';
                    });
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _sortOrder == 'newer'
                          ? CupertinoIcons.sort_down_circle
                          : CupertinoIcons.sort_up_circle,
                      key: ValueKey(_sortOrder),
                      size: 20,
                      color: const Color(0xff00DC00),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141415),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
                indicatorAnimation:TabIndicatorAnimation.elastic,
                enableFeedback: true,
              // Add more space inside each tab
              labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                indicatorColor: Colors.transparent,


                // Indicator pill with spacing
              indicator: BoxDecoration(
                color: const Color(0xFF1F2A1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withValues(alpha: 0.5)),
              ),

              // Push indicator slightly away from text baseline
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),

              // Make indicator fill only tab label, not full width
              indicatorSize: TabBarIndicatorSize.tab,

              labelColor: const Color(0xff00DC00),
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
              overlayColor: MaterialStateProperty.all(Colors.transparent),

              tabs: [
                Tab(child: _TabChip(text: 'All', count: _countFor('all'))),
                Tab(child: _TabChip(text: 'Confirmed', count: _countFor('confirmed'))),
                Tab(child: _TabChip(text: 'Pending', count: _countFor('pending'))),
              ],
            ),
          ),
        ),


        const SizedBox(height: 8),

          Expanded(
            child: Obx(() {
              if (ctr.isLoading.value) {
                return Center(child: AppLinearLoader());
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _BookingsList(
                    bookings: _getFilteredAndSorted('all'),
                    emptyHint: 'No bookings found.',
                    fmt: _fmt,
                  ),
                  _BookingsList(
                    bookings: _getFilteredAndSorted('confirmed'),
                    emptyHint: 'No confirmed bookings yet.',
                    fmt: _fmt,
                  ),
                  _BookingsList(
                    bookings: _getFilteredAndSorted('pending'),
                    emptyHint: 'No pending bookings.',
                    fmt: _fmt,
                  ),
                ],
              );

            }),
          ),
        ],
      ),
    ),
  );
}
class _TabChip extends StatelessWidget {
  const _TabChip({required this.text, required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.emptyHint,
    required this.fmt,
  });

  final List<Map<String, dynamic>> bookings;
  final String emptyHint;
  final String Function(String?) fmt;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      // return Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Text(emptyHint, style: GoogleFonts.inter(color: Colors.white)),
      //       const SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: () async {
      //           // Trigger a refresh via controller
      //           final ctr = Get.find<BookingController>();
      //           await ctr.fetchUserBookings();
      //         },
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: const Color(0xff00DC00),
      //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(8),
      //           ),
      //         ),
      //         child: Text(
      //           'Refresh Bookings',
      //           style: GoogleFonts.inter(
      //             color: Colors.white,
      //             fontSize: 14,
      //             fontWeight: FontWeight.w500,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // );
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xff292929), width: 0.5)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No Bookings Found',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don’t have any active bookings.\nStart exploring gaming cafés now!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Navigate to cafes explore screen
                  final homeController = Get.find<HomeController>();
                  homeController.onItemTapped(1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00DC00),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Explore Cafés',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final ctr = Get.find<BookingController>();
        await ctr.fetchUserBookings();
      },
      color: const Color(0xff00DC00),
      backgroundColor: const Color(0xFF1D1D1F),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final d = bookings[i];
          return BookingTicketCard(
            game: d['slot']?['gaming_type_id']?['game_name'] ?? 'Unknown',
            cafe: d['slot']?['gaming_type_id']?['cafe_name']?['cafe_name'] ?? 'Cafe',
            start: fmt(d['slot']?['time']?['start_time']),
            end: fmt(d['slot']?['time']?['end_time']),
            status: (d['status'] ?? 'Pending').toString(),
            price: double.tryParse(
              '${d['slot']?['gaming_type_id']?['single_slot_price'] ?? 0}',
            ) ??
                0,
            loc: d['slot']?['location'] ?? 'Mumbai',
            id: d['booking_id'] ?? 0,
            raw: d,
            accessCode: d['access_code'],
            bookDate: d['book_date'],
            extraServices: (d['extra_services'] as List<dynamic>?)
                ?.map((e) => ExtraService.fromJson(e as Map<String, dynamic>))
                .toList() ??
                [],
          );
        },
      ),
    );
  }
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
    required this.extraServices,
  });

  final String game, cafe, start, end, status, loc;
  final int id;
  final double price;
  final Map<String, dynamic> raw;
  final String? accessCode;
  final String? bookDate;
  final List<ExtraService> extraServices;

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
          backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: const Color(0xff00DC00).withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        .map(
          (w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : '',
        )
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
    Color _accentForStatus(String s) {
      final v = s.toLowerCase();
      if (v.contains('confirm') || v.contains('success')) return const Color(0xff00DC00); // green
      if (v.contains('pend') || v.contains('await') || v.contains('unpaid')) return const Color(0xFFF5C042); // yellow
      return Colors.white; // default for any other/unknown
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Get.to(
        () => ViewDetailScreen(booking: raw, startTime: start, endTime: end),
      ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$id',
                            style: GoogleFonts.inter(
                              color: _accentForStatus(status),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),),
                          const SizedBox(height: 2),
                          Text(
                            'Booking ID',
                            style: GoogleFonts.inter(
                              color: _accentForStatus(status).withValues(alpha: 0.75),
                              fontSize: 10,
                            ),
                          ),

                          const SizedBox(height: 8), // Reduced from 12
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Get.to(
                                () => const QrScannerView(),
                              );
                              if (result != null) {
                                _handleScannedCode(result.toString());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00DC00),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ), // very slim
                              minimumSize: const Size(
                                0,
                                28,
                              ), // optional: control height
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // avoid extra height
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
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.white38,
                                ), // Reduced from 16
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

class QrScannerView extends StatelessWidget {
  const QrScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                Get.back(result: barcode.rawValue);
              }
            },
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
}

class ExtraService {
  final String name;
  final double price;
  final int quantity;
  final double totalPrice;

  ExtraService({
    required this.name,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory ExtraService.fromJson(Map<String, dynamic> json) {
    return ExtraService(
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'],
      totalPrice: json['total_price'],
    );
  }
}
