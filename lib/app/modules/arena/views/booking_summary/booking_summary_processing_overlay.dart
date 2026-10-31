import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';

class BookingSummaryProcessingOverlay extends StatelessWidget {
  final bool isProcessing;
  final String status;

  const BookingSummaryProcessingOverlay({
    super.key,
    required this.isProcessing,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProcessing) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: BookingColors.bg.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: BookingColors.surface,
              borderRadius: BorderRadius.circular(BookingRadius.card),
              border: Border.all(color: BookingColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: BookingColors.accentBright,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  status.isNotEmpty ? status : 'Processing…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: BookingColors.textPrimary,
                    fontSize: 14,
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
