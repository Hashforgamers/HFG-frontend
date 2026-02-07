import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_feature_chips.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class SearchResultCard extends StatelessWidget {
  final String title;
  final String type;
  final String imageUrl;
  final String address;
  final List<String> features;
  final bool isOpen;
  final String distanceLabel;
  final String? etaLabel;
  final double rating;
  final VoidCallback? onViewDetails;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.type,
    required this.imageUrl,
    required this.address,
    required this.features,
    required this.isOpen,
    required this.distanceLabel,
    required this.etaLabel,
    required this.rating,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final memW = (width * dpr).round();
    const imgH = 200.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOpen ? onViewDetails : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: imgH,
                      width: double.infinity,
                      child: imageUrl.isEmpty
                          ? Container(color: const Color(0xFF1A1A1A))
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: memW,
                              memCacheHeight: (imgH * dpr).round(),
                              placeholder: (_, __) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: RainbowGlowingLoader(size: 32),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xff338125) : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '$rating',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            etaLabel == null
                                ? distanceLabel
                                : '$distanceLabel • $etaLabel',
                            style: GoogleFonts.inter(
                              color: const Color(0xff338125),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SearchResultFeatureChips(features: features),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Spacer(),
                          ElevatedButton(
                            onPressed: isOpen ? onViewDetails : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff338125),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              isOpen ? 'View Details' : 'Closed',
                              style:
                                  GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
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
