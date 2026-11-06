import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'booking_design.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/localization/app_region.dart';

/// Shown after a console slot is booked: a ticket with the café, slot and
/// payment, then one action into the player's bookings.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    this.paymentId = '',
    this.bookingId = '',
    this.cafeName = '',
    this.consoleText = '',
    required this.dateText,
    required this.timeText,
    this.method = '',
    required this.totalText,
    required this.email,
    this.onViewInvoice,
    this.accentColor = BookingColors.success,
    this.isBookingCreatedOnly = false,
  });

  /// Gateway payment id (Razorpay). Empty for wallet, pass and pay-at-café.
  final String paymentId;
  final String bookingId;
  final String cafeName;
  final String consoleText;
  final String dateText;
  final String timeText;
  final String method;
  final String totalText;
  final String email;
  final VoidCallback? onViewInvoice;
  final Color accentColor;

  /// Pay-at-café booking: nothing has been paid yet.
  final bool isBookingCreatedOnly;

  static const _muted = BookingColors.textSecondary;

  String _formattedTotal() {
    final value = totalText.trim();
    if (value.isEmpty) return '--';
    if (value.startsWith('Rs') ||
        value.startsWith('INR') ||
        value.contains(Money.symbol)) {
      return value;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return value;
    if (parsed % 1 == 0) return '${Money.symbol} ${parsed.toInt()}';
    return '${Money.symbol} ${parsed.toStringAsFixed(2)}';
  }

  /// Callers pass API times ("05:00:00 - 05:30:00", maybe "+N more");
  /// each clock time becomes "5:00 AM".
  String _prettyTime() => timeText.trim().replaceAllMapped(
    RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)(?::[0-5]\d)?\b'),
    (m) => DateFormat(
      'h:mm a',
    ).format(DateTime(2000, 1, 1, int.parse(m[1]!), int.parse(m[2]!))),
  );

  /// Callers pass the API date (yyyy-MM-dd); show it as "Sat, 31 Oct".
  String _prettyDate() {
    final parsed = DateTime.tryParse(dateText.trim());
    return parsed == null
        ? dateText.trim()
        : DateFormat('EEE, d MMM').format(parsed);
  }

  /// "razorpay_upi" -> "Razorpay Upi"; "wallet" -> "Hash Wallet".
  String _prettyMethod() {
    final raw = method.trim().toLowerCase();
    if (raw.isEmpty) return isBookingCreatedOnly ? 'Pay at café' : 'Online';
    const known = {
      'wallet': 'Hash Wallet',
      'gateway': 'UPI / Card',
      'cafe_wallet': 'Cafe Wallet',
      'pay_at_cafe': 'Pay at café',
      'none': 'Game Pass',
    };
    if (known.containsKey(raw)) return known[raw]!;
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final title = isBookingCreatedOnly ? 'Booking confirmed' : "You're booked!";
    final subtitle = isBookingCreatedOnly
        ? 'Pay at the café counter when you arrive.'
        : 'Payment received. See you at the café.';
    final reference = paymentId.trim().isNotEmpty
        ? (label: 'Payment ID', value: paymentId.trim())
        : bookingId.trim().isNotEmpty
        ? (label: 'Booking ID', value: '#${bookingId.trim()}')
        : null;

    return Scaffold(
      backgroundColor: BookingColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 220,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      HomeTokens.pink.withValues(alpha: 0.22),
                      HomeTokens.pink.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      HomeTokens.orange.withValues(alpha: 0.18),
                      HomeTokens.orange.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  // Centres the badge, title and ticket in the space above the
                  // button; still scrolls on short screens.
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: c.maxHeight - 28,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SuccessBadge(accentColor: accentColor),
                            const SizedBox(height: 18),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: BookingColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _Ticket(
                              accentColor: accentColor,
                              cafeName: cafeName.trim(),
                              consoleText: consoleText.trim(),
                              dateText: _prettyDate(),
                              timeText: _prettyTime(),
                              amountLabel: isBookingCreatedOnly
                                  ? 'To pay'
                                  : 'Paid',
                              amount: _formattedTotal(),
                              method: _prettyMethod(),
                              reference: reference,
                              onCopy: (label, value) =>
                                  _copy(context, value, '$label copied'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BookingPrimaryButton(
                    label: 'View my booking',
                    icon: Icons.arrow_forward_rounded,
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFE4E6E8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (onViewInvoice != null) {
                        onViewInvoice!.call();
                        return;
                      }
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _copy(BuildContext context, String text, String msg) {
    final value = text.trim();
    if (value.isEmpty) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: BookingColors.textOnAccent,
            size: 46,
          ),
        ),
      ),
    );
  }
}

/// Booking pass: café and console up top, a perforated tear line, then the
/// slot and payment.
class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.accentColor,
    required this.cafeName,
    required this.consoleText,
    required this.dateText,
    required this.timeText,
    required this.amountLabel,
    required this.amount,
    required this.method,
    required this.reference,
    required this.onCopy,
  });

  final Color accentColor;
  final String cafeName;
  final String consoleText;
  final String dateText;
  final String timeText;
  final String amountLabel;
  final String amount;
  final String method;
  final ({String label, String value})? reference;
  final void Function(String label, String value) onCopy;

  static const _notch = 11.0;

  @override
  Widget build(BuildContext context) {
    final hasHeader = cafeName.isNotEmpty || consoleText.isNotEmpty;
    return ClipPath(
      clipper: hasHeader ? const _TicketClipper(notchY: 82, r: _notch) : null,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasHeader) ...[
                SizedBox(
                  height: 82,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: BookingColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cafeName.isNotEmpty)
                                Text(
                                  cafeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: BookingColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (consoleText.isNotEmpty)
                                Text(
                                  consoleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: BookingColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _DashedLine(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field('Date', dateText)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Time', timeText)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field(amountLabel, amount, big: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Method', method)),
                      ],
                    ),
                  ],
                ),
              ),
              if (reference != null)
                Material(
                  color: Colors.white.withValues(alpha: 0.03),
                  child: InkWell(
                    onTap: () => onCopy(reference!.label, reference!.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            reference!.label,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reference!.value,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: BookingColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String value, {
    Color valueColor = BookingColors.textPrimary,
    bool big = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '--' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: big ? 20 : 14.5,
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Ticket._notch + 6),
      child: LayoutBuilder(
        builder: (context, c) {
          final count = (c.maxWidth / 10).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                width: 5,
                height: 1,
                color: BookingColors.borderStrong,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rounded rectangle with a half-circle notch cut into each side at [notchY].
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.notchY, required this.r});

  final double notchY;
  final double r;

  @override
  Path getClip(Size size) {
    final card = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: r));
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.notchY != notchY || old.r != r;
}
