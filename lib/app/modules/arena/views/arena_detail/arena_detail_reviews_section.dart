import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class ArenaDetailReviewsSection extends StatefulWidget {
  const ArenaDetailReviewsSection({
    super.key,
    required this.vendorId,
    this.initialReviews = const [],
  });

  final int vendorId;
  final List<dynamic> initialReviews;

  @override
  State<ArenaDetailReviewsSection> createState() =>
      _ArenaDetailReviewsSectionState();
}

class _ArenaDetailReviewsSectionState extends State<ArenaDetailReviewsSection> {
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  late Future<_VendorReviewBundle> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<_VendorReviewBundle> _loadReviews() async {
    try {
      final results = await Future.wait([
        _remoteRepo.fetchVendorReviewsSummary(vendorId: widget.vendorId),
        _remoteRepo.fetchVendorReviews(vendorId: widget.vendorId, limit: 10),
      ]);
      return _VendorReviewBundle(
        summary: results[0] as Map<String, dynamic>,
        reviews: results[1] as List<Map<String, dynamic>>,
      );
    } catch (_) {
      return _VendorReviewBundle(
        summary: const <String, dynamic>{},
        reviews: widget.initialReviews
            .map(
              (review) => <String, dynamic>{
                'title': '',
                'comment': review.toString(),
                'rating': null,
                'is_anonymous': true,
              },
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VendorReviewBundle>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final bundle =
            snapshot.data ??
            _VendorReviewBundle(
              summary: const <String, dynamic>{},
              reviews: widget.initialReviews
                  .map(
                    (review) => <String, dynamic>{
                      'title': '',
                      'comment': review.toString(),
                      'rating': null,
                      'is_anonymous': true,
                    },
                  )
                  .toList(),
            );

        final summary = bundle.summary;
        final reviews = bundle.reviews;
        final average = (summary['average'] as num?)?.toDouble() ?? 0.0;
        final total = (summary['total'] as num?)?.toInt() ?? reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Reviews',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (total > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff181818),
                  border: Border.all(color: const Color(0xff2D2D2D)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          average.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StarsRow(rating: average),
                        const SizedBox(height: 4),
                        Text(
                          '$total reviews',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          final star = 5 - index;
                          final count =
                              (summary['r$star'] as num?)?.toInt() ?? 0;
                          final ratio = total == 0 ? 0.0 : count / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  child: Text(
                                    '$star',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFC94D),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFF2C2C2C),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xff00DC00),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$count',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff181818),
                  border: Border.all(color: const Color(0xff2D2D2D)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'No reviews yet.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              )
            else
              ...reviews.map((review) {
                final title = (review['title'] ?? '').toString().trim();
                final comment = (review['comment'] ?? review['review'] ?? '')
                    .toString()
                    .trim();
                final ratingValue = (review['rating'] as num?)?.toDouble();
                final author = _reviewAuthor(review);
                final initial = author.isNotEmpty
                    ? author[0].toUpperCase()
                    : 'H';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF181818),
                        const Color(0xFF131313),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xff00DC00,
                                  ).withValues(alpha: 0.28),
                                  const Color(
                                    0xff00DC00,
                                  ).withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xff00DC00,
                                ).withValues(alpha: 0.24),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                color: const Color(0xff00DC00),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (ratingValue != null)
                                      _StarsRow(rating: ratingValue),
                                    if (ratingValue != null)
                                      const SizedBox(width: 8),
                                    if (ratingValue != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFFC94D,
                                          ).withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFFFC94D,
                                            ).withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Text(
                                          ratingValue.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFFFC94D),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      review['created_at'] != null
                                          ? _formatReviewDate(
                                              review['created_at'].toString(),
                                            )
                                          : '',
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.white.withValues(alpha: 0.12),
                            size: 28,
                          ),
                        ],
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            comment,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ] else if (title.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'No written comment provided.',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  String _reviewAuthor(Map<String, dynamic> review) {
    final isAnonymous = review['is_anonymous'] == true;
    if (isAnonymous) return 'Anonymous';
    final user = review['user'];
    if (user is Map) {
      final name = (user['name'] ?? user['username'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    }
    final rawName = (review['user_name'] ?? review['author'] ?? '')
        .toString()
        .trim();
    if (rawName.isNotEmpty) return rawName;
    return 'HashForGamers User';
  }

  String _formatReviewDate(String raw) {
    try {
      final parsed = DateTime.parse(raw).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${parsed.day} ${months[parsed.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

class _VendorReviewBundle {
  const _VendorReviewBundle({required this.summary, required this.reviews});

  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> reviews;
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = rating >= index + 1;
        final half = !filled && rating > index && rating < index + 1;
        return Icon(
          half ? Icons.star_half_rounded : Icons.star_rounded,
          size: 14,
          color: filled || half ? const Color(0xFFFFC94D) : Colors.white24,
        );
      }),
    );
  }
}
