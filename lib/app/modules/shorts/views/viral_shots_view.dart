import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/viral_shorts_controller.dart';
import 'short_video_player.dart';

class ViralShotsSection extends StatelessWidget {
  final controller = Get.put(YouTubeShortsController());

   ViralShotsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRENDING SHORTS',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.isLoading.value) return _shimmerRow();
          if (controller.shorts.isEmpty) {
            return Center(
                child: Text('No shorts found',
                    style: GoogleFonts.inter(color: Colors.white)));
          }

          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.shorts.length,
              itemBuilder: (context, index) {
                final short = controller.shorts[index];
                return _buildItem(short, index);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _shimmerRow() {
    return SizedBox(
      height: 220,
      child: Shimmer.fromColors(
        baseColor: const Color(0xff1E1E1E),
        highlightColor: const Color(0xff2C2C2C),
        child: Row(
          children: List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.all(5),
              width: 120,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(YouTubeShort short, int index) {
    return GestureDetector(
      onTap: () => Get.to(() =>
          ShortVideoPlayer(shorts: controller.shorts, initialIndex: index)),
      child: Container(
        margin: const EdgeInsets.only(right: 18),
        width: 125,
        height: 220,
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
                placeholder: (context, url) =>
                    Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) =>
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
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
                              color: Colors.white, fontSize: 11),
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
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => Get.to(() => ShortVideoPlayer(
                        shorts: controller.shorts, initialIndex: index)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff75F94C),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
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
