import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/core/localization/app_region.dart';

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

  static const Color _wallet = Color(0xFF42D7FF);

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
          accentColor: _wallet,
        ),
      _SummaryLine(
        hasWalletFlow ? remainingAmountLabel : 'Payable Now',
        dueNow,
        emphasized: true,
      ),
    ];

    return BookingCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BookingColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: BookingColors.accentBright,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment summary', style: BookingText.title(context)),
                    const SizedBox(height: 2),
                    Text(
                      hasWalletFlow
                          ? 'What the booking costs and what you pay now.'
                          : 'Breakdown of your final payable amount.',
                      style: BookingText.muted(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hero: amount to pay now.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BookingColors.accent.withValues(alpha: 0.14),
                  BookingColors.surfaceHigh,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BookingColors.accent.withValues(alpha: 0.22),
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
                    color: BookingColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${Money.symbol}${dueNow.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: BookingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasWalletFlow
                      ? 'Wallet is used first; the remaining amount is shown above.'
                      : 'Final amount charged for this booking.',
                  style: BookingText.muted(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('1 · Booking charges'),
          const SizedBox(height: 10),
          ...bookingCharges.map(_buildSummaryLine),
          if (savingsApplied.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('2 · Savings applied'),
            const SizedBox(height: 10),
            ...savingsApplied.map(_buildSummaryLine),
          ],
          const SizedBox(height: 10),
          _sectionLabel(
            hasWalletFlow ? '3 · How you will pay' : '2 · Final payment',
          ),
          const SizedBox(height: 10),
          ...howYouPay.map(_buildSummaryLine),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BookingColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BookingColors.borderSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _miniMetric(
                    'Grand Total',
                    '${Money.symbol}${totalPrice.toStringAsFixed(2)}',
                    BookingColors.textPrimary,
                  ),
                ),
                Container(width: 1, height: 34, color: BookingColors.border),
                Expanded(
                  child: _miniMetric(
                    'You Save',
                    '${Money.symbol}${savings.toStringAsFixed(2)}',
                    BookingColors.success,
                  ),
                ),
                if (walletAppliedAmount > 0) ...[
                  Container(width: 1, height: 34, color: BookingColors.border),
                  Expanded(
                    child: _miniMetric(
                      'Wallet',
                      '${Money.symbol}${walletAppliedAmount.toStringAsFixed(2)}',
                      _wallet,
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
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: BookingColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSummaryLine(_SummaryLine line) {
    final prefix = line.isDeduction ? '-${Money.symbol}' : '${Money.symbol}';
    return _paymentRow(
      line.label,
      '$prefix${line.amount.toStringAsFixed(2)}',
      labelColor: line.isDeduction ? BookingColors.success : null,
      valueColor:
          line.accentColor ?? (line.isDeduction ? BookingColors.success : null),
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
              color: BookingColors.textMuted,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isEmphasized
            ? BookingColors.accent.withValues(alpha: 0.08)
            : BookingColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmphasized
              ? BookingColors.accent.withValues(alpha: 0.20)
              : BookingColors.borderSoft,
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
                color: labelColor ?? BookingColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isEmphasized ? 14 : 13,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? BookingColors.textPrimary,
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
