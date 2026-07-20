import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/viral_shorts_controller.dart';
import 'short_video_player.dart';

class ViralShotsSection extends StatelessWidget {
  final YouTubeShortsController controller = Get.put(YouTubeShortsController());

  ViralShotsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isLoading.value && controller.shorts.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Trending ',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Shorts',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00DC00),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.isLoading.value) return _shimmerRow();
            if (controller.shorts.isEmpty) {
              return Center(
                child: Text(
                  'No shorts found',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.separated(
                cacheExtent: 600,
                scrollDirection: Axis.horizontal,
                itemCount: controller.shorts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final short = controller.shorts[index];
                  return RepaintBoundary(child: _buildItem(short, index));
                },
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _shimmerRow() {
    return SizedBox(
      height: 220,
      child: Shimmer.fromColors(
        baseColor: const Color(0xff1E1E1E),
        highlightColor: const Color(0xff2C2C2C),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: 120,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(YouTubeShort short, int index) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index),
      ),
      child: Container(
        height: 220,
        width: 125,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xff1E1E1E),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: short.thumbnail,
                height: 220,
                width: 125,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: short.channelImage,
                          height: 24,
                          width: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          short.channelName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    short.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => Get.to(
                      () => ShortVideoPlayer(
                        shorts: controller.shorts,
                        initialIndex: index,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00DC00),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 20,
                      ),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Watch',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
