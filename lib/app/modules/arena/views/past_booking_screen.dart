import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/home/models/live_session_booking.dart';
import 'package:hash/app/modules/arena/services/booking_food_order_service.dart';
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
  final BookingController ctr = Get.isRegistered<BookingController>()
      ? Get.find<BookingController>()
      : Get.put(BookingController());
  late TabController _tabController;
  String _sortOrder = 'newer'; // 'newer' or 'older'
  final prefs = locator<SharedPreferences>();
  bool hasRated = false;

  void getRatingBool() {
    final hasRated = prefs.getBool('hasRatedApp') ?? false;
    this.hasRated = hasRated;
  }

  @override
  void initState() {
    super.initState();
    getRatingBool();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctr.fetchUserBookings(forceRefresh: false).then((_) {
        if (!mounted) return;
        if (!hasRated && ctr.userBookings.isNotEmpty) {
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
    if (s.contains('pend') || s.contains('await') || s.contains('unpaid'))
      return 'pending';
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xff404040),
          title: const Text(
            "Enjoying our app?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "We’d love your feedback! Please rate us on the Play Store.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // "Maybe later" – do NOT set hasRatedApp
                // Next successful payment will set ratePromptPending again.
              },
              child: const Text(
                "Maybe Later",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await prefs.setBool('hasRatedApp', true); // never show again
                final InAppReview inAppReview = InAppReview.instance;
                await inAppReview.openStoreListing();
              },
              child: const Text(
                "Rate Us",
                style: TextStyle(color: const Color(0xff00DC00)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xff404040),
          title: const Text(
            "Enjoying our app?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "We’d love your feedback! Please rate us on the Play Store.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // "Maybe later" – do NOT set hasRatedApp
                // Next successful payment will set ratePromptPending again.
              },
              child: const Text(
                "Maybe Later",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasRatedApp', true); // never show again
                await prefs.setBool('ratePromptPending', false); // extra safety
                final InAppReview inAppReview = InAppReview.instance;
                await inAppReview.openStoreListing();
              },
              child: const Text(
                "Rate Us",
                style: TextStyle(color: const Color(0xff00DC00)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNextSessionHero() {
    final confirmed =
        ctr.userBookings
            .where((booking) => _statusBucket(booking['status']) == 'confirmed')
            .toList()
          ..sort((a, b) {
            final aId = int.tryParse('${a['booking_id'] ?? 0}') ?? 0;
            final bId = int.tryParse('${b['booking_id'] ?? 0}') ?? 0;
            return bId.compareTo(aId);
          });
    final booking = confirmed.isEmpty ? null : confirmed.first;
    if (booking == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121712),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x3300DC00)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x2200DC00),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_business_rounded,
                color: Color(0xFF00DC00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO SESSION QUEUED',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lock a setup and pull up.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Get.find<HomeController>().onItemTapped(1),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00DC00),
              ),
              child: const Text('FIND SETUP'),
            ),
          ],
        ),
      );
    }

    final slot = booking['slot'] is Map
        ? Map<String, dynamic>.from(booking['slot'] as Map)
        : const <String, dynamic>{};
    final gaming = slot['gaming_type_id'] is Map
        ? Map<String, dynamic>.from(slot['gaming_type_id'] as Map)
        : const <String, dynamic>{};
    final cafe = gaming['cafe_name'] is Map
        ? Map<String, dynamic>.from(gaming['cafe_name'] as Map)
        : const <String, dynamic>{};
    final time = slot['time'] is Map
        ? Map<String, dynamic>.from(slot['time'] as Map)
        : const <String, dynamic>{};
    final cafeName = (cafe['cafe_name'] ?? cafe['name'] ?? 'Gaming café')
        .toString();
    final game = (gaming['game_name'] ?? 'Gaming setup').toString();
    final date = (booking['book_date'] ?? 'Date locked').toString();
    final start = _fmt(time['start_time']?.toString());
    final end = _fmt(time['end_time']?.toString());
    final code = (booking['access_code'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132417), Color(0xFF111318)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0x6600DC00)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B840),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LOCKED IN',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${booking['booking_id'] ?? '--'}',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            cafeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$game · $date · $start–$end',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (code.isNotEmpty)
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ACCESS  $code',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF93F80A),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ),
              if (code.isNotEmpty) const SizedBox(width: 9),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00DC00),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.confirmation_number_rounded, size: 17),
                  label: Text(
                    'OPEN TICKET',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                Text(
                  'Sessions',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  splashRadius: 18,
                  tooltip: _sortOrder == 'newer'
                      ? 'Newest first'
                      : 'Oldest first',
                  onPressed: () {
                    setState(() {
                      _sortOrder = _sortOrder == 'newer' ? 'older' : 'newer';
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
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() => _buildNextSessionHero()),
          const SizedBox(height: 12),
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
                indicatorAnimation: TabIndicatorAnimation.elastic,
                enableFeedback: true,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                indicatorColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color(0xFF1F2A1C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withValues(alpha: 0.5)),
                ),
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 4,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF93F80A),
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                tabs: [
                  Tab(
                    child: _TabChip(text: 'All Runs', count: _countFor('all')),
                  ),
                  Tab(
                    child: _TabChip(
                      text: 'Locked',
                      count: _countFor('confirmed'),
                    ),
                  ),
                  Tab(
                    child: _TabChip(
                      text: 'Pending',
                      count: _countFor('pending'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Obx(() {
              if (ctr.isLoading.value && ctr.userBookings.isEmpty) {
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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
            border: Border.all(color: Color(0xff292929), width: 0.5),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
        await ctr.fetchUserBookings(forceRefresh: true);
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
            cafe:
                d['slot']?['gaming_type_id']?['cafe_name']?['cafe_name'] ??
                'Cafe',
            start: fmt(d['slot']?['time']?['start_time']),
            end: fmt(d['slot']?['time']?['end_time']),
            status: (d['status'] ?? 'Pending').toString(),
            price:
                double.tryParse(
                  '${d['slot']?['gaming_type_id']?['single_slot_price'] ?? 0}',
                ) ??
                0,
            loc: d['slot']?['location'] ?? 'Mumbai',
            id: d['booking_id'] ?? 0,
            raw: d,
            accessCode: d['access_code'],
            bookDate: d['book_date'],
            extraServices:
                (d['extra_services'] as List<dynamic>?)
                    ?.map(
                      (e) => ExtraService.fromJson(e as Map<String, dynamic>),
                    )
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
  BookingFoodOrderService get _foodOrderService => BookingFoodOrderService();

  String _readFirstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final normalized = (value ?? '').toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return '';
  }

  String _resolveConsoleId(Map<String, dynamic> qrData) {
    return _readFirstNonEmpty([
      qrData['console_id'],
      qrData['consoleId'],
      qrData['id'],
      qrData['console'] is Map ? qrData['console']['id'] : null,
      qrData['console'] is Map ? qrData['console']['console_id'] : null,
    ]);
  }

  String _resolveGameId(Map<String, dynamic> qrData) {
    final slot = raw['slot'] as Map<String, dynamic>?;
    final gamingType = slot?['gaming_type_id'] as Map<String, dynamic>?;
    return _readFirstNonEmpty([
      raw['game_id'],
      raw['gameId'],
      slot?['game_id'],
      slot?['gameId'],
      gamingType?['game_id'],
      gamingType?['gameId'],
      gamingType?['id'],
      qrData['game_id'],
      qrData['gameId'],
    ]);
  }

  String _resolveVendorId(Map<String, dynamic> qrData) {
    final slot = raw['slot'] as Map<String, dynamic>?;
    final gamingType = slot?['gaming_type_id'] as Map<String, dynamic>?;
    final cafe = gamingType?['cafe_name'] as Map<String, dynamic>?;
    return _readFirstNonEmpty([
      raw['vendor_id'],
      raw['vendorId'],
      slot?['vendor_id'],
      slot?['vendorId'],
      gamingType?['vendor_id'],
      gamingType?['vendorId'],
      cafe?['vendor_id'],
      cafe?['vendorId'],
      cafe?['id'],
      qrData['vendor_id'],
      qrData['vendorId'],
    ]);
  }

  bool _isCompletedBooking() {
    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus.contains('completed') ||
        normalizedStatus.contains('session_completed')) {
      return true;
    }

    bool truthy(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final raw = value?.toString().trim().toLowerCase() ?? '';
      return raw == 'true' || raw == '1' || raw == 'yes';
    }

    String readFirst(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final completedFlag = [
      raw['is_completed'],
      raw['completed'],
      raw['session_completed'],
      raw['review_allowed'],
      raw['can_review'],
      raw['is_review_allowed'],
    ].any(truthy);
    if (completedFlag) return true;

    final completedAt = readFirst([
      raw['completed_at'],
      raw['session_completed_at'],
      raw['ended_at'],
      raw['session_end_at'],
    ]);
    return completedAt.isNotEmpty;
  }

  Future<void> _showWriteReviewDialog(BuildContext context) async {
    if (!_isCompletedBooking()) {
      debugPrint(
        'Review blocked on client -> booking_id=$id, status=$status, raw=$raw',
      );
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Review will be available once this session is marked completed.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final vendorId = int.tryParse(_resolveVendorId(const {}));
    final bookingId = id;
    if (vendorId == null || vendorId <= 0 || bookingId <= 0) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Review details are incomplete for this booking.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final rootMessenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _WriteReviewDialog(
        cafe: cafe,
        vendorId: vendorId,
        bookingId: bookingId,
        rootMessenger: rootMessenger,
      ),
    );
  }

  void _showScanMessage(
    ScaffoldMessengerState messenger, {
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title: $message',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _showScanSuccessDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xff00DC00).withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff00DC00).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff00DC00).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xff00DC00).withValues(alpha: 0.30),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xff00DC00),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan Completed',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enjoy gaming. Your console has been queued successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00DC00),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleScannedCode(
    BuildContext context,
    ScaffoldMessengerState messenger,
    String scannedCode,
  ) async {
    try {
      debugPrint('Booking QR scan raw payload: $scannedCode');

      Map<String, dynamic> qrData;
      final trimmedCode = scannedCode.trim();
      try {
        final decoded = jsonDecode(trimmedCode);
        if (decoded is Map<String, dynamic>) {
          qrData = decoded;
        } else if (decoded is Map) {
          qrData = Map<String, dynamic>.from(decoded);
        } else {
          qrData = {'console_id': decoded};
        }
      } catch (_) {
        qrData = {'console_id': trimmedCode};
      }

      // QR is the source of truth for console, booking payload is the source of truth for booking/game/vendor.
      final consoleId = _resolveConsoleId(qrData);
      final gameId = _resolveGameId(qrData);
      final vendorId = _resolveVendorId(qrData);
      final bookingId = id.toString();

      debugPrint(
        'Booking QR scan parsed -> console_id=$consoleId, game_id=$gameId, vendor_id=$vendorId, booking_id=$bookingId',
      );

      // Validate that all required fields are present
      if (consoleId.isEmpty || gameId.isEmpty || vendorId.isEmpty) {
        debugPrint(
          'Booking QR scan validation failed -> missing required fields',
        );
        _showScanMessage(
          messenger,
          title: 'Error',
          message:
              'Missing console, game, or vendor details for queue check-in.',
          backgroundColor: Colors.red.withValues(alpha: 0.88),
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

      debugPrint('Booking QR scan API success -> $result');

      await _showScanSuccessDialog(context);
    } catch (e) {
      String errorMessage = 'Failed to process QR code';

      if (e is FormatException) {
        errorMessage = 'Invalid QR Code format. Please scan a valid QR code.';
      } else {
        errorMessage = 'Failed to verify booking: ${e.toString()}';
      }

      debugPrint('Booking QR scan error -> $e');

      _showScanMessage(
        messenger,
        title: 'Error',
        message: errorMessage,
        backgroundColor: Colors.red.withValues(alpha: 0.88),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveSession = LiveSessionBooking.fromPastBooking(raw);
    final canWriteReview = _isCompletedBooking();
    final canOrderFood =
        liveSession != null &&
        liveSession.vendorId.isNotEmpty &&
        !canWriteReview &&
        DateTime.now().isBefore(liveSession.startAt);
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
      if (v.contains('confirm') || v.contains('success'))
        return const Color(0xff00DC00); // green
      if (v.contains('pend') || v.contains('await') || v.contains('unpaid'))
        return const Color(0xFFF5C042); // yellow
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1E22), Color(0xFF131417), Color(0xFF0D0E10)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Booking ID',
                                style: GoogleFonts.inter(
                                  color: _accentForStatus(
                                    status,
                                  ).withValues(alpha: 0.75),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
                              ),
                              splashRadius: 16,
                              tooltip: 'Scan QR',
                              onPressed: () async {
                                if (!context.mounted) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final result = await Get.to(
                                  () => const QrScannerView(),
                                );
                                if (!context.mounted) return;
                                if (result != null) {
                                  _handleScannedCode(
                                    context,
                                    messenger,
                                    result.toString(),
                                  );
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 86,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$cafe - $game',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$start - $end',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: $formattedDate',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Status: $formattedStatus',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (canOrderFood || canWriteReview) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canOrderFood)
                              SizedBox(
                                height: 30,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _foodOrderService
                                        .orderForUpcomingSession(
                                          context: context,
                                          booking: raw,
                                        );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xff00DC00),
                                    ),
                                    foregroundColor: const Color(0xff00DC00),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(
                                    Icons.fastfood_rounded,
                                    size: 13,
                                  ),
                                  label: Text(
                                    'Order Food',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (canWriteReview)
                              SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _showWriteReviewDialog(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFF3C44E),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFF3C44E,
                                      ).withValues(alpha: 0.35),
                                    ),
                                    backgroundColor: const Color(
                                      0xFFF3C44E,
                                    ).withValues(alpha: 0.08),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 12),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.star_rounded, size: 12),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.star_half_rounded,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rate Session',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.045),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Access Code',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                displayAccessCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 20;

    final Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height / 2 - radius);
    path.arcToPoint(
      Offset(0, size.height / 2 + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2 + radius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WriteReviewDialog extends StatefulWidget {
  const _WriteReviewDialog({
    required this.cafe,
    required this.vendorId,
    required this.bookingId,
    required this.rootMessenger,
  });

  final String cafe;
  final int vendorId;
  final int bookingId;
  final ScaffoldMessengerState rootMessenger;

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _commentController;
  int _selectedRating = 5;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF1B1C1F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2F3237)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2F3237)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF4C64F)),
      ),
      counterStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
    );
  }

  String get _ratingLabel {
    switch (_selectedRating) {
      case 5:
        return 'Loved it';
      case 4:
        return 'Really good';
      case 3:
        return 'Decent experience';
      case 2:
        return 'Needs work';
      default:
        return 'Poor experience';
    }
  }

  String get _ratingHint {
    switch (_selectedRating) {
      case 5:
        return 'Tell others what made this cafe stand out.';
      case 4:
        return 'Share what worked well and what could improve.';
      case 3:
        return 'A balanced review helps the next player.';
      case 2:
        return 'Point out the main issues clearly.';
      default:
        return 'Be specific so the team can fix it.';
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await locator<RemoteRepoInterface>().createCafeReview(
        vendorId: widget.vendorId,
        bookingId: widget.bookingId,
        rating: _selectedRating,
        title: _titleController.text,
        comment: _commentController.text,
        isAnonymous: _isAnonymous,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.rootMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Review submitted successfully.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xff00DC00).withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.rootMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17181B), Color(0xFF111214)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2D31)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C64F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'CAFE REVIEW',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF4C64F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'How was ${widget.cafe}?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rate the session and leave a short review. Your feedback helps other players choose better.',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ratingLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ratingHint,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return Padding(
                          padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedRating = star),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: star <= _selectedRating
                                    ? const Color(
                                        0xFFF4C64F,
                                      ).withValues(alpha: 0.14)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: star <= _selectedRating
                                      ? const Color(
                                          0xFFF4C64F,
                                        ).withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Icon(
                                star <= _selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFF4C64F),
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                maxLength: 120,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('Add a short title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('What stood out for you?'),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CheckboxListTile(
                  value: _isAnonymous,
                  onChanged: (value) =>
                      setState(() => _isAnonymous = value ?? false),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  activeColor: const Color(0xFFF4C64F),
                  checkColor: Colors.black,
                  title: Text(
                    'Post anonymously',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    'Your name will be hidden from other users.',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10.5,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF343434)),
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4C64F),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
