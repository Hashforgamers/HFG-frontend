import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

class HomeGamePassCard extends StatelessWidget {
  final VoidCallback onTap;

  const HomeGamePassCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 200,
        width: double.infinity,
        // brand-gradient rim, as on the other home cards
        padding: const EdgeInsets.all(HomeFrostCard.rim),
        decoration: BoxDecoration(
          gradient: HomeTokens.brandRim(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20 - HomeFrostCard.rim),
              child: CachedNetworkImage(
                imageUrl:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075177/gamepassbg_jkkq7b.png',
                height: 200,
                width: double.infinity,
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
            Positioned(
              left: 20,
              top: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pay with ',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback:
                                HomeTokens.brandGradient.createShader,
                            child: Text(
                              'Hash Pass',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get the digital membership card now.\nUse at any participating gaming cafe.',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 32),
                  HomeBrandButton(
                    label: 'Buy Now',
                    onTap: onTap,
                    height: 30,
                    fontSize: 12,
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
