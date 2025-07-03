import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';

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
                  style: GoogleFonts.bebasNeue(
                    fontSize: 36,
                    color: Colors.green,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelColor: const Color(0xff338125),
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                  tabs: const [
                    Tab(child: Text('All',style: TextStyle(color: Colors.green),)),
                    Tab(child: Text('Upcoming',style: TextStyle(color: Colors.green),)),
                    Tab(child: Text('Completed',style: TextStyle(color: Colors.green),)),
                  ],
                ),
              ),
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
                      return _BookingCard(
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.game,
    required this.cafe,
    required this.start,
    required this.end,
    required this.status,
    required this.price,
    required this.loc,
    required this.id,
    required this.raw,
  });

  final String game, cafe, start, end, status, loc;
  final double price;
  final int id;
  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    String formattedStatus = status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1).toLowerCase()
            : '')
        .join(' ');
    const mainRed = Color(0xFFEF5658); // App's main red
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Get.to(
          () => ViewDetailScreen(booking: raw, startTime: start, endTime: end)),
      child: ClipPath(
        clipper: TicketClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181A20),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
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
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Booking ID',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
