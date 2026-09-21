import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';

class BookingSummaryUserSection extends StatelessWidget {
  final String userName;
  final VoidCallback onChangeUser;

  const BookingSummaryUserSection({
    super.key,
    required this.userName,
    required this.onChangeUser,
  });

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BookingColors.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: BookingColors.border),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 22,
              color: BookingColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BOOKING FOR', style: BookingText.sectionLabel(context)),
                const SizedBox(height: 4),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: BookingColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeUser,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: BookingColors.accentBright,
            ),
            child: Text(
              'Change',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: BookingColors.accentBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
