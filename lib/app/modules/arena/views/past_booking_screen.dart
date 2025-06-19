import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen_detail.dart';
import 'package:barcode_widget/barcode_widget.dart';

// NOTE: add to pubspec.yaml under dependencies:
// barcode_widget: ^2.0.4

class PastBookingsScreen extends StatefulWidget {
  const PastBookingsScreen({super.key});
  @override
  State<PastBookingsScreen> createState() => _PastBookingsScreenState();
}

class _PastBookingsScreenState extends State<PastBookingsScreen> {
  final BookingController ctr = Get.put(BookingController());

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
    WidgetsBinding.instance.addPostFrameCallback((_) => ctr.fetchUserBookings());
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Past Bookings'), backgroundColor: Colors.black),
    body: Obx(() {
      if (ctr.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (ctr.userBookings.isEmpty) {
        return const Center(child: Text('No past bookings.', style: TextStyle(color: Colors.white)));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemCount: ctr.userBookings.length,
        itemBuilder: (_, i) {
          final d = ctr.userBookings[i];
          return _CssTicket(
            game: d['slot']?['gaming_type_id']?['game_name'] ?? 'Unknown',
            cafe: d['slot']?['gaming_type_id']?['cafe_name']['cafe_name'] ?? 'Cafe',
            start: _fmt(d['slot']?['time']?['start_time']),
            end: _fmt(d['slot']?['time']?['end_time']),
            status: d['status'] ?? 'Pending',
            price: double.tryParse('${d['slot']?['gaming_type_id']?['single_slot_price'] ?? 0}') ?? 0,
            loc: d['slot']?['location'] ?? 'Mumbai',
            id: d['booking_id'] ?? 0,
            raw: d,
          );
        },
      );
    }),
  );
}

class _CssTicket extends StatelessWidget {
  const _CssTicket({
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
    final barcodeData = 'ID:$id|$game|$loc|$start-$end|INR${price.toStringAsFixed(2)}|$status'
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.to(() => ViewDetailScreen(booking: raw, startTime: start, endTime: end)),
      child: Row(
        children: [
          _buildStub(context),
          _buildCheck(context, barcodeData),
        ],
      ),
    );
  }

  Widget _buildStub(BuildContext context) => Container(
    width: 110,
    height: 211,
    decoration: BoxDecoration(
      color: const Color(0xffef5658),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(children: [
      _notchCircle(right: -6, top: 60),
      _notchCircle(right: -6, bottom: 60),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('ADMIT', style: TextStyle(fontSize: 10, color: Colors.white)),
            const SizedBox(width: 6),
            Container(width: 2, height: 22, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(
              child: Text('INVITE\n$id',
                  style: const TextStyle(fontSize: 8, color: Colors.black), maxLines: 2),
            ),
          ]),
          const Spacer(),
          Text('${id % 1000}',
              style: const TextStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('FOR YOU', style: TextStyle(color: Colors.black, fontSize: 12)),
        ]),
      ),
    ]),
  );

  Widget _buildCheck(BuildContext context, String barcodeData) => Expanded(
    child: Container(
      height: 211,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Stack(children: [
        _notchCircle(left: -6, top: 60),
        _notchCircle(left: -6, bottom: 60),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TICKET',
                style: GoogleFonts.bebasNeue(fontSize: 28, color: const Color(0xffef5658))),
            const SizedBox(height: 4),
            Text('$cafe - $game ',
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),

            const SizedBox(height: 12),
            Row(children: [
              _detail('DATE', DateFormat.MMMd().format(DateTime.now())),
              _detail('TIME', '$start - $end'),
              _detail('STATUS', status.toUpperCase()),
            ]),
            const SizedBox(height: 14),
            // Row(children: [
            //   _detail('GATE', 'G${id % 5 + 1}'),
            //   _detail('ROW', '${id % 20}'),
            //   _detail('SEAT', '${id % 100}'),
            // ]),
            const Spacer(),
            Center(
              child: BarcodeWidget(
                height: 50,
                width: 200,
                data: barcodeData,
                barcode: Barcode.code128(),
                drawText: false,
              ),
            ),
          ]),
        ),
      ]),
    ),
  );

  Widget _notchCircle({double? left, double? right, double? top, double? bottom}) => Positioned(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
  );

  Widget _detail(String t, String v) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 18.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 2, color: const Color(0xffef5658)),
        const SizedBox(height: 4),
        Text(t, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    ),
  );
}