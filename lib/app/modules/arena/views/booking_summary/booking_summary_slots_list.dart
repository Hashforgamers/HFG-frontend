import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingSummarySlotsList extends StatelessWidget {
  final List<Map<String, dynamic>> selectedSlots;

  const BookingSummarySlotsList({
    super.key,
    required this.selectedSlots,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedSlots.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey.shade800),
      itemBuilder: (context, index) {
        final slot = selectedSlots[index];
        final double slotPrice = (slot['price'] ?? 50.0).toDouble();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot['console_label'] ?? 'PC ${slot['pc_index']}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${slot['start_time']} - ${slot['end_time']}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${slotPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xff00DC00),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
