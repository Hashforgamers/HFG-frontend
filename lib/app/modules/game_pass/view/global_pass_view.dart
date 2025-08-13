import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

enum GlobalPassCardType { rightImage, leftImage }

class GlobalPassView extends StatefulWidget {
  final TabController tabController;
  const GlobalPassView({super.key, required this.tabController});

  @override
  State<GlobalPassView> createState() => _GlobalPassViewState();
}

class _GlobalPassViewState extends State<GlobalPassView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildLabel(),
        const SizedBox(height: 30),
        _buildGlobalPassCard(
          image:
              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075178/globalpass1_o2shqg.png',
          title: 'Daily Hash Pass',
          info: '24 Hours @ Rs.500',
          color: Color(0xFFE6D009),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildGlobalPassCard(
          type: GlobalPassCardType.rightImage,
          image:
              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075179/globalpass2_frqa5h.png',
          title: 'Monthly Hash Pass',
          info: '30 Days @ Rs.1500',
          color: Color(0xFF6DFB60),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildGlobalPassCard(
          image:
              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075180/globalpass3_lnlwiu.png',
          title: 'Yearly Hash Pass',
          info: '365 Days @Rs.4500',
          color: Color(0xFF09E6C5),
          onTap: () {},
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGlobalPassCard({
    GlobalPassCardType type = GlobalPassCardType.leftImage,
    required String image,
    required String title,
    required String info,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: image,
                height: 200,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: type == GlobalPassCardType.rightImage ? 0 : 20,
              right: type == GlobalPassCardType.rightImage ? 20 : 0,
              child: Column(
                crossAxisAlignment: type == GlobalPassCardType.rightImage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png',
                    height: 26,
                    width: 26,
                    placeholder: (_, _) =>
                        const Center(child: RainbowGlowingLoader(size: 20)),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'use to book at any cafe',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Buy Pass',
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

  Widget _buildLabel() {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl:
              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/globalPassIcon_t5cod0.png',
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          placeholder: (_, _) =>
              const Center(child: RainbowGlowingLoader(size: 40)),
          errorWidget: (_, _, _) => Container(
            color: Colors.grey,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buy a Global Hash Pass',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
