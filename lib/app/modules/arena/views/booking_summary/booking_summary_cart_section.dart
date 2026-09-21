import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';

class BookingSummaryCartSection extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String summaryText;

  const BookingSummaryCartSection({
    super.key,
    required this.cartItems,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return BookingCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fastfood_rounded,
                size: 18,
                color: BookingColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text('Food & beverages', style: BookingText.title(context)),
              const SizedBox(width: 8),
              BookingStatusPill(
                label: summaryText,
                tone: BookingPillTone.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...cartItems.map((item) {
            final itemQuantity = (item['qty'] as num?)?.toInt() ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            final total = price * itemQuantity;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BookingColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$itemQuantity×',
                      style: GoogleFonts.inter(
                        color: BookingColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      item['name']?.toString() ?? 'Item',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: BookingColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: BookingColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
