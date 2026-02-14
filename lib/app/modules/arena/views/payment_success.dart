import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    this.paymentId = '#453545',
    required this.dateText,
    required this.timeText,
    this.method = 'Google Pay',
    required this.totalText,
    required this.email,
    this.onViewInvoice,
    this.accentColor = const Color(0xFF2EE66A),
  });

  final String paymentId;
  final String dateText;
  final String timeText;
  final String method;
  final String totalText;
  final String email;
  final VoidCallback? onViewInvoice;
  final Color accentColor;

  static const _bg = Color(0xFF0A0F0C);
  static const _text = Colors.white;
  static const _muted = Color(0xFF95A29A);
  static const _card = Color(0xFF121915);
  static const _cardBorder = Color(0xFF233128);

  String _safeValue(String value, {String fallback = '--'}) {
    final v = value.trim();
    return v.isEmpty ? fallback : v;
  }

  String _formattedTotal() {
    final value = totalText.trim();
    if (value.isEmpty) return 'Paid';
    if (value.startsWith('Rs') ||
        value.startsWith('INR') ||
        value.contains('₹')) {
      return value;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return value;
    if (parsed % 1 == 0) return '₹ ${parsed.toInt()}';
    return '₹ ${parsed.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final details = <_TxnItem>[
      _TxnItem(
        icon: Icons.calendar_today_outlined,
        label: 'Date',
        value: _safeValue(dateText),
      ),
      _TxnItem(
        icon: Icons.schedule_outlined,
        label: 'Time',
        value: _safeValue(timeText),
      ),
      _TxnItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Payment Method',
        value: _safeValue(method, fallback: 'Online'),
      ),
      _TxnItem(
        icon: Icons.confirmation_number_outlined,
        label: 'Payment ID',
        value: _safeValue(paymentId),
        copyable: true,
      ),
      if (email.trim().isNotEmpty)
        _TxnItem(
          icon: Icons.alternate_email,
          label: 'Email',
          value: email.trim(),
          copyable: true,
        ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.30),
                      accentColor.withValues(alpha: 0.01),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _SuccessBadge(accentColor: accentColor),
                      const SizedBox(height: 20),
                      Text(
                        'Payment Complete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your booking is confirmed and ready.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PaymentIdChip(
                        paymentId: _safeValue(paymentId),
                        accentColor: accentColor,
                        onCopy: () =>
                            _copy(context, paymentId, 'Payment ID copied'),
                      ),
                      const SizedBox(height: 16),
                      _AmountCard(
                        total: _formattedTotal(),
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 16),
                      _DetailsCard(
                        items: details,
                        onCopy: (label, value) =>
                            _copy(context, value, '$label copied'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (onViewInvoice != null) {
                          onViewInvoice!.call();
                          return;
                        }
                        Navigator.of(context).maybePop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: const Color(0xFF0D1B12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
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
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: 144,
          height: 144,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.24),
                  ),
                ),
              ),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.34),
                      accentColor.withValues(alpha: 0.07),
                    ],
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Image.asset(
                  'assets/checkmark.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) {
                    return const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0C1A11),
                      size: 44,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentIdChip extends StatelessWidget {
  const _PaymentIdChip({
    required this.paymentId,
    required this.accentColor,
    required this.onCopy,
  });

  final String paymentId;
  final Color accentColor;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: PaymentSuccessScreen._card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaymentSuccessScreen._cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                paymentId,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onCopy,
              child: const Icon(
                Icons.copy_rounded,
                size: 15,
                color: PaymentSuccessScreen._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.total, required this.accentColor});

  final String total;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: PaymentSuccessScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaymentSuccessScreen._cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.currency_rupee_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Paid',
                  style: GoogleFonts.inter(
                    color: PaymentSuccessScreen._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.items, required this.onCopy});

  final List<_TxnItem> items;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PaymentSuccessScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaymentSuccessScreen._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Transaction Details',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < items.length; i++) ...[
            _DetailRow(
              item: items[i],
              onCopy: items[i].copyable
                  ? () => onCopy(items[i].label, items[i].value)
                  : null,
            ),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: PaymentSuccessScreen._cardBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.item, this.onCopy});

  final _TxnItem item;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 16,
              color: PaymentSuccessScreen._muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.inter(
                color: PaymentSuccessScreen._muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    item.value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onCopy,
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: PaymentSuccessScreen._muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnItem {
  const _TxnItem({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
}
