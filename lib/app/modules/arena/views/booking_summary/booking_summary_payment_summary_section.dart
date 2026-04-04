import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingSummaryPaymentSummarySection extends StatelessWidget {
  final double totalPrice;
  final double discount;
  final double subtotal;
  final double slotsSubtotal;
  final double cartSubtotal;
  final double squadDiscountAmount;
  final double extraControllerFare;
  final double walletAppliedAmount;
  final double remainingGatewayAmount;
  final String remainingAmountLabel;
  final bool hasSlots;
  final bool hasCartItems;

  const BookingSummaryPaymentSummarySection({
    super.key,
    required this.totalPrice,
    required this.discount,
    required this.subtotal,
    required this.slotsSubtotal,
    required this.cartSubtotal,
    this.squadDiscountAmount = 0,
    this.extraControllerFare = 0,
    this.walletAppliedAmount = 0,
    this.remainingGatewayAmount = 0,
    this.remainingAmountLabel = 'Remaining to Pay Online',
    required this.hasSlots,
    required this.hasCartItems,
  });

  @override
  Widget build(BuildContext context) {
    final savings = discount + squadDiscountAmount;
    final dueNow = remainingGatewayAmount > 0
        ? remainingGatewayAmount
        : totalPrice;
    final hasWalletFlow = walletAppliedAmount > 0 || remainingGatewayAmount > 0;

    final bookingCharges = <_SummaryLine>[
      if (hasSlots) _SummaryLine('Slots', slotsSubtotal),
      if (extraControllerFare > 0)
        _SummaryLine('Extra Controllers', extraControllerFare),
      if (hasCartItems) _SummaryLine('Food & Beverages', cartSubtotal),
      _SummaryLine('Subtotal', subtotal, emphasized: true),
      _SummaryLine('GST', 0),
    ];

    final savingsApplied = <_SummaryLine>[
      if (discount > 0) _SummaryLine('Discount', discount, isDeduction: true),
      if (squadDiscountAmount > 0)
        _SummaryLine('Squad Discount', squadDiscountAmount, isDeduction: true),
    ];

    final howYouPay = <_SummaryLine>[
      if (walletAppliedAmount > 0)
        _SummaryLine(
          'Paid from Wallet',
          walletAppliedAmount,
          isDeduction: true,
          accentColor: const Color(0xff42D7FF),
        ),
      _SummaryLine(
        hasWalletFlow ? remainingAmountLabel : 'Payable Now',
        dueNow,
        emphasized: true,
        accentColor: const Color(0xff00DC00),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff00DC00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xff00DC00),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasWalletFlow
                          ? 'See what the booking costs and what you need to pay now.'
                          : 'Simple breakdown of your final payable amount.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xff00DC00).withValues(alpha: 0.18),
                  const Color(0xff0F2B11),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xff00DC00).withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to pay now',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${dueNow.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff00DC00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasWalletFlow
                      ? 'Wallet will be used first. The remaining amount is shown above.'
                      : 'This is the final amount that will be charged for this booking.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('1. Booking Charges'),
          const SizedBox(height: 10),
          ...bookingCharges.map(_buildSummaryLine),
          if (savingsApplied.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('2. Savings Applied'),
            const SizedBox(height: 10),
            ...savingsApplied.map(_buildSummaryLine),
          ],
          const SizedBox(height: 10),
          _sectionLabel(
            hasWalletFlow ? '3. How You Will Pay' : '2. Final Payment',
          ),
          const SizedBox(height: 10),
          ...howYouPay.map(_buildSummaryLine),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _miniMetric(
                    'Grand Total',
                    '₹${totalPrice.toStringAsFixed(2)}',
                    Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _miniMetric(
                    'You Save',
                    '₹${savings.toStringAsFixed(2)}',
                    const Color(0xff00DC00),
                  ),
                ),
                if (walletAppliedAmount > 0) ...[
                  Container(
                    width: 1,
                    height: 34,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _miniMetric(
                      'Wallet',
                      '₹${walletAppliedAmount.toStringAsFixed(2)}',
                      const Color(0xff42D7FF),
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

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white54,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSummaryLine(_SummaryLine line) {
    final prefix = line.isDeduction ? '-₹' : '₹';
    return _paymentRow(
      line.label,
      '$prefix${line.amount.toStringAsFixed(2)}',
      labelColor: line.isDeduction ? const Color(0xffCDEFCF) : null,
      valueColor:
          line.accentColor ??
          (line.isDeduction ? const Color(0xff00DC00) : null),
      isEmphasized: line.emphasized,
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEmphasized
            ? const Color(0xff00DC00).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmphasized
              ? const Color(0xff00DC00).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isEmphasized ? 13 : 12,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
                color: labelColor ?? Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isEmphasized ? 14 : 13,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine {
  final String label;
  final double amount;
  final bool emphasized;
  final bool isDeduction;
  final Color? accentColor;

  const _SummaryLine(
    this.label,
    this.amount, {
    this.emphasized = false,
    this.isDeduction = false,
    this.accentColor,
  });
}
