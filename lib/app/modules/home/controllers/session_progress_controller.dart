import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/home/models/live_session_booking.dart';

class SessionProgressController extends GetxController {
  final Rxn<LiveSessionBooking> currentBooking = Rxn<LiveSessionBooking>();
  final RxDouble progress = 0.0.obs;
  final RxString countdownText = ''.obs;
  final RxString timeRangeText = ''.obs;

  List<LiveSessionBooking> _bookings = <LiveSessionBooking>[];
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  void syncFromPastBookings(List<Map<String, dynamic>> pastBookings) {
    _bookings =
        pastBookings
            .map(LiveSessionBooking.fromPastBooking)
            .whereType<LiveSessionBooking>()
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    _recompute();
  }

  void _recompute() {
    final now = DateTime.now();

    final active = _bookings.where((booking) {
      return !now.isBefore(booking.startAt) && !now.isAfter(booking.endAt);
    }).toList();

    if (active.isEmpty) {
      currentBooking.value = null;
      progress.value = 0;
      countdownText.value = '';
      timeRangeText.value = '';
      return;
    }

    final booking = active.last;
    currentBooking.value = booking;

    final totalMs = booking.endAt.difference(booking.startAt).inMilliseconds;
    final elapsedMs = now.difference(booking.startAt).inMilliseconds;
    final rawProgress = totalMs <= 0 ? 1.0 : (elapsedMs / totalMs);
    progress.value = rawProgress.clamp(0.0, 1.0);

    final remaining = booking.endAt.difference(now);
    final remainingSeconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    countdownText.value =
        'Ends in ${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';

    final fmt = DateFormat('h:mm a');
    timeRangeText.value =
        '${fmt.format(booking.startAt)} -> ${fmt.format(booking.endAt)}';
  }
}
