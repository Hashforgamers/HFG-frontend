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
    required this.hasSlots,
    required this.hasCartItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (hasSlots)
            _paymentRow(
              'Slots',
              '₹${slotsSubtotal.toStringAsFixed(2)}',
            ),
          if (extraControllerFare > 0)
            _paymentRow(
              'Extra Controllers',
              '₹${extraControllerFare.toStringAsFixed(2)}',
            ),
          if (hasCartItems)
            _paymentRow(
              'Food & Beverages',
              '₹${cartSubtotal.toStringAsFixed(2)}',
            ),
          _paymentRow(
            'Subtotal',
            '₹${subtotal.toStringAsFixed(2)}',
          ),
          if (discount > 0)
            _paymentRow(
              'Discount',
              '-₹${discount.toStringAsFixed(2)}',
              color: const Color(0xff00DC00),
            ),
          if (squadDiscountAmount > 0)
            _paymentRow(
              'Squad Discount',
              '-₹${squadDiscountAmount.toStringAsFixed(2)}',
              color: const Color(0xff00DC00),
            ),
          _paymentRow('GST', '₹0.00'),
          Divider(
            color: Colors.grey.shade800,
            thickness: 1,
            height: 24,
          ),
          _paymentRow(
            'GRAND TOTAL',
            '₹${totalPrice.toStringAsFixed(2)}',
            bold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
