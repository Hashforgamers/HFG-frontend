import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return BottomAppBar(
      color: const Color(0xFF0F0F0F),
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Payable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹ ${totalPrice.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xff00DC00),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xff00DC00)),
              ),
              child: ElevatedButton(
                onPressed: isProcessing ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 23,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        showSelectPass ? 'Select Pass' : (buttonLabel ?? 'Pay'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
