import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/widgets/glow_neon_loader.dart';
import '../controllers/review_controller.dart';

class ReviewPage extends StatelessWidget {
  final ReviewController reviewController = Get.put(ReviewController());

  @override
  Widget build(BuildContext context) {
    // Fetch reviews when the page loads
    final String pid = 'PID22';
    reviewController.getReviews(pid);

    return ListView(
      shrinkWrap: true,
      children: [
        ElevatedButton(
          onPressed: () {
            // Example token and review data
            String token = 'your_jwt_token_here';
            double rating = 3.5;
            String comment = 'Great product, recommended! user 3 last';

            reviewController.addReview(token, pid, rating, comment);
          },
          child: Text('Add Review'),
        ),
        Obx(() {
          if (reviewController.isLoading.value) {
            return Center(
              child: RainbowGlowingLoader(size: 50),
            );
          }
          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: reviewController.reviews.length,
            itemBuilder: (context, index) {
              final review = reviewController.reviews[index];
              print('rev ${review['reviews'][index]['comment']}');
              return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: review['reviews'].length,
                  itemBuilder: (context, index) {
                    {
                      return ReviewWidget(
                        rating: review['reviews'][index]['rating'] ?? 0.0,
                        comment: review['reviews'][index]['comment'] ?? '',
                        user: review['reviews'][index]['user_id'] ?? '',
                      );
                    }
                  });
            },
          );
        }),
      ],
    );
  }
}

class ReviewWidget extends StatelessWidget {
  final double rating;
  final String comment;
  final String user;

  const ReviewWidget({
    Key? key,
    required this.rating,
    required this.comment,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: Colors.black26,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 20),
              const SizedBox(width: 5),
              Text(
                rating.toString(),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'by $user',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
