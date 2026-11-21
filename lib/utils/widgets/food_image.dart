import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

/// A food item's picture, or the default food cover when the item has none or
/// it fails to load.
class FoodImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const FoodImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final url = this.url?.trim() ?? '';
    if (url.isEmpty) return const FoodCover();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => const ColoredBox(
        color: Color(0xFF2A2A2A),
        child: Center(child: RainbowGlowingLoader(size: 14)),
      ),
      errorWidget: (_, _, _) => const FoodCover(),
    );
  }
}

/// Default food cover (grey with spoon and fork), filling its box.
class FoodCover extends StatelessWidget {
  const FoodCover({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/food_placeholder.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
