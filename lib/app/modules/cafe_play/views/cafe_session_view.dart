import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_checkout_sheet.dart';

/// Tracks a cafe session: "Waiting for PC" while reserved, a countdown to
/// `ends_at` once active. Only `active` from the server means play started.
class CafeSessionView extends StatefulWidget {
  const CafeSessionView({super.key, required this.initial});

  final CafeSession initial;

  @override
  State<CafeSessionView> createState() => _CafeSessionViewState();
}

class _CafeSessionViewState extends State<CafeSessionView>
    with WidgetsBindingObserver {
  static const _reservedPoll = Duration(seconds: 2);
  static const _activePoll = Duration(seconds: 20);

  late CafeSession _session = widget.initial;
  Timer? _poll;
  Timer? _tick;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
    }
  }

  void _schedule() {
    _poll?.cancel();
    if (_session.isTerminal) return;
    final delay = _session.state == CafeSessionState.reserved
        ? _reservedPoll
        : _activePoll;
    _poll = Timer(delay, _refresh);
  }

  Future<void> _refresh() async {
    if (_fetching || _session.isTerminal) return;
    _fetching = true;
    try {
      final next = await CafePlayApi.instance.getSession(_session.id);
      if (mounted) setState(() => _session = next);
    } on CafePlayException catch (e) {
      debugPrint('Cafe session poll failed: $e');
    } finally {
      _fetching = false;
      if (mounted) _schedule();
    }
  }

  String _remaining() {
    final end = _session.endsAt;
    if (end == null) return '--:--';
    var left = end.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final s = left.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final checkout = _session.checkout;
    final isWallet = _session.kind == 'wallet';
    final (
      IconData icon,
      Color color,
      String title,
      String subtitle,
    ) = switch (_session.state) {
      CafeSessionState.reserved => (
        Icons.hourglass_top_rounded,
        BookingColors.warning,
        'Waiting for PC',
        isWallet
            ? '${cafeMoney(_session.amount)} is on hold. You\'ll be charged once the PC unlocks.'
            : 'Unlocking your booked PC…',
      ),
      CafeSessionState.active => (
        Icons.sports_esports_rounded,
        BookingColors.accent,
        'You\'re playing',
        isWallet
            ? '${cafeMoney(_session.amount)} paid from cafe wallet'
            : 'Booked session',
      ),
      CafeSessionState.completed => (
        Icons.check_circle_rounded,
        BookingColors.accent,
        'Session complete',
        'Thanks for playing!',
      ),
      CafeSessionState.failed => (
        Icons.error_outline_rounded,
        BookingColors.danger,
        'PC didn\'t start',
        isWallet
            ? 'No money was charged — the hold has been released.'
            : 'Please try scanning again or ask the desk.',
      ),
      CafeSessionState.cancelled => (
        Icons.cancel_outlined,
        BookingColors.danger,
        'Session cancelled',
        'Please contact the cafe desk.',
      ),
      CafeSessionState.unknown => (
        Icons.help_outline_rounded,
        BookingColors.textSecondary,
        'Checking status…',
        '',
      ),
    };

    return Scaffold(
      backgroundColor: BookingColors.bg,
      appBar: AppBar(
        backgroundColor: BookingColors.bg,
        foregroundColor: BookingColors.textPrimary,
        elevation: 0,
        title: Text(
          checkout == null
              ? 'Cafe session'
              : '${checkout.cafeName} · PC ${checkout.consoleNumber}',
          style: BookingText.title(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BookingSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BookingSpacing.xxxl),
              Icon(icon, color: color, size: 64),
              const SizedBox(height: BookingSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: BookingText.display(context),
              ),
              const SizedBox(height: BookingSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: BookingText.secondary(context),
              ),
              if (_session.state == CafeSessionState.reserved) ...[
                const SizedBox(height: BookingSpacing.xxl),
                const Center(
                  child: CircularProgressIndicator(
                    color: BookingColors.warning,
                  ),
                ),
              ],
              if (_session.state == CafeSessionState.active) ...[
                const SizedBox(height: BookingSpacing.xxl),
                Text(
                  _remaining(),
                  textAlign: TextAlign.center,
                  style: BookingText.display(context).copyWith(
                    fontSize: 48,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'time left',
                  textAlign: TextAlign.center,
                  style: BookingText.muted(context),
                ),
              ],
              if (checkout != null) ...[
                const SizedBox(height: BookingSpacing.xxl),
                BookingCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cafe wallet balance',
                          style: BookingText.secondary(context),
                        ),
                      ),
                      Text(
                        cafeMoney(checkout.availableBalance),
                        style: BookingText.title(context),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              BookingSecondaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
