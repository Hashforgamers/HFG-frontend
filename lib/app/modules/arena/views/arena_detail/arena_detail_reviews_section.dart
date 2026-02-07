import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArenaDetailReviewsSection extends StatelessWidget {
  final List<dynamic> reviews;

  const ArenaDetailReviewsSection({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...reviews.map(
          (review) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff181818),
              border: Border.all(color: const Color(0xff2D2D2D)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.white,
              ),
              title: Text(
                review.toString(),
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
