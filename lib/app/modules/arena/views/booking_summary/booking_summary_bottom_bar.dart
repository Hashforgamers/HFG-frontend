import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

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
      color: HomeTokens.ink,
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
                gradient: const LinearGradient(
                  colors: [HomeTokens.greenBright, HomeTokens.green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: HomeTokens.green.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
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
                    ? const AppLinearLoader(width: 34, height: 3)
                    : Text(
                        showSelectPass ? 'Select Pass' : (buttonLabel ?? 'Pay'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          // White on bright green failed contrast; the rest of
                          // the app's green CTAs use black labels.
                          color: Colors.black,
                          letterSpacing: 0.2,
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
