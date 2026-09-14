import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

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
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        border: Border.all(color: HomeTokens.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BOOKING FOR',
                style: HomeTokens.eyebrow(HomeTokens.textTertiary),
              ),
              const SizedBox(height: 6),
              Text(
                userName,
                style: HomeTokens.title(16),
              ),
            ],
          ),
          TextButton(
            onPressed: onChangeUser,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Text(
              'Change',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: HomeTokens.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
