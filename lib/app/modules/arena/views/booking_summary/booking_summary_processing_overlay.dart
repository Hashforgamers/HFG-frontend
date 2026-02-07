import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF338125)),
            ),
            const SizedBox(height: 16),
            Text(
              status.isNotEmpty ? status : 'Processing...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
