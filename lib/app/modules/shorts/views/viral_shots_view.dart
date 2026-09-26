import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/viral_shorts_controller.dart';
import '../widgets/short_card.dart';
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
          const HomeSectionTitle(title: 'Trending ', accent: 'Shorts'),
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
              height: 250,
              child: ListView.separated(
                cacheExtent: 600,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: controller.shorts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
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
      height: 250,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1C1C1E),
        highlightColor: const Color(0xFF2C2C2E),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => Container(
            width: 138,
            decoration: const ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40)),
              ),
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(YouTubeShort short, int index) {
    return ShortCard(
      thumbnail: short.thumbnail,
      title: short.title,
      channelName: short.channelName,
      channelImage: short.channelImage,
      onTap: () => Get.to(
        () => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index),
      ),
    );
  }
}
