import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class CafeCarousel extends StatelessWidget {
  final LatLng? Function() userLatLngGetter;
  const CafeCarousel({super.key, required this.userLatLngGetter});

  @override
  Widget build(BuildContext context) {
    final CybercafesController ctr = Get.find();

    if (ctr.isLoading.value) {
      return const Center(child: RainbowGlowingLoader(size: 50));
    }

    if (ctr.cybercafes.isEmpty) {
      return const Center(child: Text('No cybercafes available'));
    }

    const dummyImgs = [
      'https://next-level.gg/assets/cafes/11.jpg',
      'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
      'https://media.assettype.com/afkgaming/2024-04/e11d1515-bb0d-48a5-9ad9-1ddfdef286ef/Untitled_design_117_.png',
      'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
      'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg',
    ];

    return SizedBox(
      height: 230,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 8, top: 10),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: ctr.cybercafes.length,
        itemBuilder: (_, i) {
          final cafe = ctr.cybercafes[i];
          final image = dummyImgs[i % dummyImgs.length];

          return Container(
            width: 300,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xff0E0E0E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: image,
                  width: 300,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: RainbowGlowingLoader(size: 40)),
                  errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.error, color: Colors.white)),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                    ),
                    child: Text(
                      cafe['cafe_name'] ?? 'Unnamed',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
