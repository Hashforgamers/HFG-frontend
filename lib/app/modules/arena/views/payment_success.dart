import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    this.paymentId = "#453545",
    required this.dateText,
    required this.timeText,
    this.method = "Google Pay",
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

  static const _bg = Color(0xFF0F0F0F);
  static const _card = Color(0xFF171717);
  static const _text = Colors.white;
  static const _muted = Color(0xFF9AA1A9);
  static const _border = Color(0xFF262626);

  // Reusable text styles (const to avoid rebuilds)
  static const _titleStyle = TextStyle(
    color: _text, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.2,
  );
  static const _headlineStyle = TextStyle(
    color: _text, fontSize: 24, fontWeight: FontWeight.w600,
  );
  static const _sectionStyle = TextStyle(
    color: _text, fontSize: 18, fontWeight: FontWeight.w700,
  );
  static const _labelStyle = TextStyle(
    color: _muted, fontSize: 15, fontWeight: FontWeight.w500,
  );
  static const _valueStyle = TextStyle(
    color: _text, fontSize: 16, fontWeight: FontWeight.w600,
  );
  static const _strongValueStyle = TextStyle(
    color: _text, fontSize: 16, fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onViewInvoice,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accentColor, width: 2),
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            child: const Text("Continue"),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                const SizedBox(height: 8),
                const Text("PAID", textAlign: TextAlign.center, style: _titleStyle),
                const SizedBox(height: 24),

                _GlowBadge(accentColor: accentColor),
                const SizedBox(height: 24),

                const Text("Payment Completed", textAlign: TextAlign.center, style: _headlineStyle),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, color: _muted, size: 18),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onLongPress: () => _copy(context, paymentId, "Payment ID copied"),
                      child: Text("ID: $paymentId", style: const TextStyle(color: _muted, fontSize: 16)),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Transaction details", style: _sectionStyle),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow("Date", dateText),
                      const _DividerLine(),
                      _DetailRow("Time", timeText),
                      const _DividerLine(),
                      _DetailRow("Payment Method", method),
                      const _DividerLine(),
                      const _SpacerTight(),
                      _DetailRow("Total", totalText, valueStyle: _strongValueStyle),
                      const _DividerLine(),
                      _DetailRow(
                        "Email",
                        email,
                        onCopy: () => _copy(context, email, "Email copied"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _copy(BuildContext context, String text, String msg) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
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

class _GlowBadge extends StatelessWidget {
  const _GlowBadge({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Payment successful",
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor,
          boxShadow: [
            BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 40, spreadRadius: 2),
          ],
        ),
        child:  Image.asset('assets/checkmark.png'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueStyle, this.onCopy});

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
           Expanded(
            child: Text(label, style: PaymentSuccessScreen._labelStyle),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: GestureDetector(
              onLongPress: onCopy,
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: valueStyle ?? PaymentSuccessScreen._valueStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: PaymentSuccessScreen._border);
}

// Small spacer that keeps card compact
class _SpacerTight extends StatelessWidget {
  const _SpacerTight();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
