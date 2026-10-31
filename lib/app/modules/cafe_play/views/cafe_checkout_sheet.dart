import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_live_session_sync.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_qr_scanner_view.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_session_view.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:intl/intl.dart';

/// Cafe wallet amounts are INR paise regardless of the app's region.
String cafeMoney(int paise) => Money.format(
  paise / 100,
  currency: 'INR',
  decimals: paise % 100 == 0 ? 0 : 2,
);

/// Scan a PC QR, then let the gamer start a paid booking or buy time from
/// their balance at that cafe. The backend deducts the wallet on PC ack.
Future<void> startCafeScanFlow(BuildContext context) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final raw = await navigator.push<String>(
    MaterialPageRoute(builder: (_) => const CafeQrScannerView()),
  );
  if (raw == null) return;
  final qr = CafePlayApi.extractQrToken(raw);
  if (qr == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'That isn\'t a Hash PC code. Scan the QR on the PC screen.',
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  final session = await showModalBottomSheet<CafeSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CafeCheckoutSheet(qr: qr),
  );
  if (session == null) return;
  unawaited(CafeSessionStore.remember(session.id));
  navigator.push(
    MaterialPageRoute(builder: (_) => CafeSessionView(initial: session)),
  );
}

class CafeCheckoutSheet extends StatefulWidget {
  const CafeCheckoutSheet({super.key, required this.qr});

  final String qr;

  @override
  State<CafeCheckoutSheet> createState() => _CafeCheckoutSheetState();
}

class _CafeCheckoutSheetState extends State<CafeCheckoutSheet> {
  final _api = CafePlayApi.instance;

  CafeCheckout? _checkout;
  String? _error;
  String? _notice;
  bool _loading = true;
  bool _submitting = false;
  CafeDuration? _selected;

  // An idempotency key is reused for retries of the same intent (e.g. after a
  // timeout) and regenerated only when the intent changes.
  String? _intent;
  String? _intentKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? notice}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final checkout = await _api.getCheckout(widget.qr);
      if (!mounted) return;
      // Only priced durations can be selected; keep the previous pick if it
      // still exists after a reload.
      final active = checkout.activeSessionId;
      if (active != null) unawaited(CafeSessionStore.remember(active));
      final durations = checkout.policy.durations
          .where((d) => d.isAvailable)
          .toList();
      setState(() {
        _checkout = checkout;
        _notice = notice;
        _selected = durations.isEmpty
            ? null
            : durations.firstWhere(
                (d) =>
                    d.minutes == _selected?.minutes &&
                    d.amount == _selected?.amount,
                orElse: () => durations.first,
              );
        _loading = false;
      });
    } on CafePlayException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _keyFor(String intent) {
    if (_intent != intent || _intentKey == null) {
      _intent = intent;
      _intentKey = CafePlayApi.newIdempotencyKey();
    }
    return _intentKey!;
  }

  Future<void> _submit(
    Future<CafeSession> Function(String key) call,
    String intent,
  ) async {
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final session = await call(_keyFor(intent));
      if (mounted) Navigator.of(context).pop(session);
    } on CafePlayException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.isUnknownOutcome) {
        // Keep the key: tapping again safely replays the same request.
        setState(() => _notice = '${e.message} Tap again to retry.');
        return;
      }
      _intent = null;
      _intentKey = null;
      if (e.statusCode == 409) {
        // Price change, busy PC or low balance — refresh so the user sees
        // the current state before confirming again.
        await _load(notice: e.message);
      } else {
        setState(() => _notice = e.message);
      }
    }
  }

  Future<void> _openActive(String sessionId) async {
    setState(() => _submitting = true);
    try {
      final session = await _api.getSession(sessionId);
      if (mounted) Navigator.of(context).pop(session);
    } on CafePlayException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _notice = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B0C10), Color(0xFF050506)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BookingRadius.sheet),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BookingSpacing.lg,
            BookingSpacing.md,
            BookingSpacing.lg,
            BookingSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BookingColors.borderStrong,
                    borderRadius: BorderRadius.circular(BookingRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: BookingSpacing.lg),
              Flexible(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _checkout == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: BookingColors.accent),
        ),
      );
    }
    final checkout = _checkout;
    if (checkout == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            color: BookingColors.danger,
            size: 40,
          ),
          const SizedBox(height: BookingSpacing.md),
          Text(
            _error ?? 'Could not load this PC.',
            textAlign: TextAlign.center,
            style: BookingText.body(context),
          ),
          const SizedBox(height: BookingSpacing.xl),
          BookingSecondaryButton(label: 'Try again', onPressed: _load),
        ],
      );
    }

    final policy = checkout.policy;
    final selected = _selected;
    final selectedAmount = selected?.amount;
    final canAfford =
        selectedAmount != null && checkout.availableBalance >= selectedAmount;
    final anyAvailable = policy.durations.any((d) => d.isAvailable);
    final unavailableReason = policy.durations
        .map((d) => d.unavailableReason)
        .firstWhere((r) => r != null, orElse: () => null);

    final hasActive = checkout.activeSessionId != null;
    final showBuy = !hasActive && policy.durations.isNotEmpty;
    final _CheckoutStatus status;
    if (hasActive) {
      status = const _CheckoutStatus('Session running', _CheckoutTone.live);
    } else if (!policy.selfService) {
      status = const _CheckoutStatus('Ask at the desk', _CheckoutTone.warning);
    } else if (policy.durations.isNotEmpty && !anyAvailable) {
      status = const _CheckoutStatus('Unavailable', _CheckoutTone.warning);
    } else if (selectedAmount != null && !canAfford) {
      status = const _CheckoutStatus('Top up needed', _CheckoutTone.warning);
    } else {
      status = const _CheckoutStatus('Ready to play', _CheckoutTone.live);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CheckoutGlassCard(
            cafeName: checkout.cafeName,
            consoleNumber: checkout.consoleNumber,
            balance: checkout.availableBalance,
            selected: showBuy ? selected : null,
            status: status,
            footer: showBuy
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in policy.durations)
                        _DurationChip(
                          duration: d,
                          selected: identical(d, selected),
                          onTap: _submitting || !d.isAvailable
                              ? null
                              : () => setState(() => _selected = d),
                        ),
                    ],
                  )
                : null,
            sessionRunning: hasActive,
            footerLabel: checkout.bookings.isEmpty
                ? 'BUY PLAY TIME'
                : 'OR BUY A NEW SESSION',
          ),
          if (_notice != null) ...[
            const SizedBox(height: BookingSpacing.md),
            _Notice(text: _notice!),
          ],
          if (hasActive) ...[
            const SizedBox(height: BookingSpacing.xl),
            BookingPrimaryButton(
              label: 'View running session',
              icon: Icons.play_circle_fill_rounded,
              loading: _submitting,
              onPressed: () => _openActive(checkout.activeSessionId!),
            ),
          ] else ...[
            if (!policy.selfService) ...[
              const SizedBox(height: BookingSpacing.md),
              const _Notice(
                text:
                    'Self check-in is turned off at this cafe. Please ask at the desk.',
              ),
            ],
            if (checkout.bookings.isNotEmpty) ...[
              const SizedBox(height: BookingSpacing.xl),
              Text('YOUR BOOKINGS', style: BookingText.sectionLabel(context)),
              const SizedBox(height: BookingSpacing.sm),
              for (final b in checkout.bookings)
                _BookingTile(
                  booking: b,
                  enabled: policy.selfService && !_submitting,
                  onStart: () => _submit(
                    (key) => _api.startBooking(
                      qr: widget.qr,
                      bookingId: b.bookingId,
                      idempotencyKey: key,
                    ),
                    'booking:${b.bookingId}',
                  ),
                ),
            ],
            if (showBuy) ...[
              const SizedBox(height: BookingSpacing.lg),
              if (!anyAvailable)
                _Notice(
                  text:
                      'Play time can\'t be bought on this PC right now. Please ask at the cafe desk.'
                      '${unavailableReason == null ? '' : '\n\n$unavailableReason'}',
                )
              else ...[
                if (selectedAmount != null && !canAfford)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BookingSpacing.md),
                    child: _Notice(
                      text:
                          'Not enough cafe balance. Top up ${cafeMoney(selectedAmount - checkout.availableBalance)} at the cafe desk.',
                    ),
                  ),
                BookingPrimaryButton(
                  label: selectedAmount == null
                      ? 'Select a duration'
                      : 'Pay ${cafeMoney(selectedAmount)} from cafe wallet',
                  icon: Icons.account_balance_wallet_rounded,
                  loading: _submitting,
                  enabled: policy.selfService && canAfford,
                  onPressed: selected == null || selectedAmount == null
                      ? null
                      : () => _submit(
                          (key) => _api.buyWalletTime(
                            qr: widget.qr,
                            duration: selected,
                            idempotencyKey: key,
                          ),
                          'wallet:${selected.minutes}:$selectedAmount',
                        ),
                ),
                const SizedBox(height: BookingSpacing.sm),
                Text(
                  'Amount is held now and charged only when the PC unlocks.',
                  textAlign: TextAlign.center,
                  style: BookingText.muted(context),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

// Same visual language as the home LiveSessionGlassCard: dark glass panel,
// brand-green accents, START → END style figures and an inset status strip.
const Color _brandGreen = Color(0xFF00DC00);

enum _CheckoutTone { live, warning }

class _CheckoutStatus {
  const _CheckoutStatus(this.label, this.tone);

  final String label;
  final _CheckoutTone tone;

  Color get color =>
      tone == _CheckoutTone.live ? _brandGreen : BookingColors.warning;
}

class _CheckoutGlassCard extends StatefulWidget {
  const _CheckoutGlassCard({
    required this.cafeName,
    required this.consoleNumber,
    required this.balance,
    required this.selected,
    required this.status,
    required this.footer,
    required this.footerLabel,
    required this.sessionRunning,
  });

  final String cafeName;
  final int consoleNumber;

  /// Paise.
  final int balance;
  final CafeDuration? selected;
  final _CheckoutStatus status;
  final Widget? footer;
  final String footerLabel;
  final bool sessionRunning;

  @override
  State<_CheckoutGlassCard> createState() => _CheckoutGlassCardState();
}

class _CheckoutGlassCardState extends State<_CheckoutGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.75,
    upperBound: 1.25,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.selected?.amount;
    final left = amount == null ? null : widget.balance - amount;
    final usage = amount == null || widget.balance <= 0
        ? 0.0
        : (amount / widget.balance).clamp(0.0, 1.0);
    final statusColor = widget.status.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF050506).withValues(alpha: 0.98),
                const Color(0xFF0B0C10).withValues(alpha: 0.97),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -56,
                right: -50,
                child: _Glow(
                  size: 140,
                  color: _brandGreen.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -90,
                left: -60,
                child: _Glow(
                  size: 170,
                  color: const Color(0xFF7D43FF).withValues(alpha: 0.24),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(statusColor),
                  const SizedBox(height: 12),
                  _figures(amount),
                  if (widget.footer != null) ...[
                    const SizedBox(height: 10),
                    _panel(statusColor, usage, left),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(Color statusColor) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: _brandGreen.withValues(alpha: 0.85)),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.desktop_windows_rounded,
            size: 12,
            color: _brandGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${widget.cafeName.trim()} · PC ${widget.consoleNumber}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          widget.sessionRunning
              ? 'LIVE'
              : widget.status.tone == _CheckoutTone.live
              ? 'READY'
              : 'HOLD',
          style: GoogleFonts.inter(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _figures(int? amount) {
    final selected = widget.selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Figure(
            label: 'CAFE WALLET',
            value: cafeMoney(widget.balance),
            valueColor: Colors.white,
            caption: 'Only usable here',
            captionColor: _brandGreen,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
        const SizedBox(width: 10),
        _Figure(
          label: widget.sessionRunning ? 'SESSION' : 'PLAY TIME',
          value: widget.sessionRunning
              ? 'Live'
              : amount == null
              ? '--'
              : cafeMoney(amount),
          valueColor: _brandGreen,
          caption: widget.sessionRunning
              ? 'Running on this PC'
              : selected == null
              ? 'Pick a duration'
              : selected.label,
          captionColor: Colors.white70,
          alignEnd: true,
        ),
      ],
    );
  }

  Widget _panel(Color statusColor, double usage, int? left) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.footerLabel,
            style: GoogleFonts.spaceGrotesk(
              color: _brandGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          widget.footer!,
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  widthFactor: usage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.status.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (left != null && left >= 0)
                Text(
                  '${cafeMoney(left)} left after',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.caption,
    required this.captionColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String caption;
  final Color captionColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.inter(
            color: captionColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.enabled,
    required this.onStart,
  });

  final CafeBookingOption booking;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    final time = (booking.startsAt != null && booking.endsAt != null)
        ? '${fmt.format(booking.startsAt!)} – ${fmt.format(booking.endsAt!)}'
        : '';
    return BookingCard(
      margin: const EdgeInsets.only(bottom: BookingSpacing.sm),
      padding: const EdgeInsets.all(BookingSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.gameName, style: BookingText.body(context)),
                if (time.isNotEmpty)
                  Text(time, style: BookingText.secondary(context)),
                if (!booking.canStart && (booking.reason ?? '').isNotEmpty)
                  Text(
                    booking.reason!,
                    style: BookingText.muted(
                      context,
                    ).copyWith(color: BookingColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BookingSpacing.sm),
          SizedBox(
            width: 96,
            child: BookingPrimaryButton(
              label: 'Start',
              height: 40,
              enabled: enabled && booking.canStart,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final CafeDuration duration;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final amount = duration.amount;
    final available = duration.isAvailable && amount != null;
    return Opacity(
      opacity: available ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF132A22)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? _brandGreen.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _brandGreen.withValues(alpha: 0.18),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  duration.label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  available ? cafeMoney(amount) : 'Unavailable',
                  style: GoogleFonts.inter(
                    color: selected ? _brandGreen : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BookingSpacing.md),
      decoration: BoxDecoration(
        color: BookingColors.warningDim,
        borderRadius: BorderRadius.circular(BookingRadius.chip),
      ),
      child: Text(
        text,
        style: BookingText.secondary(
          context,
        ).copyWith(color: BookingColors.warning),
      ),
    );
  }
}
