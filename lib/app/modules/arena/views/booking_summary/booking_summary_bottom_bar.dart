import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';

class BookingSummaryBottomBar extends StatelessWidget {
  final double totalPrice;
  final bool isProcessing;
  final bool showSelectPass;
  final String? buttonLabel;
  final VoidCallback onPressed;

  const BookingSummaryBottomBar({
    super.key,
    required this.totalPrice,
    required this.isProcessing,
    required this.showSelectPass,
    this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BookingBottomBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total payable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    color: BookingColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: BookingColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 168,
            child: BookingPrimaryButton(
              label: showSelectPass ? 'Select Pass' : (buttonLabel ?? 'Pay'),
              icon: isProcessing
                  ? null
                  : (showSelectPass
                        ? Icons.videogame_asset_rounded
                        : Icons.lock_rounded),
              loading: isProcessing,
              enabled: !isProcessing,
              onPressed: isProcessing ? null : onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
