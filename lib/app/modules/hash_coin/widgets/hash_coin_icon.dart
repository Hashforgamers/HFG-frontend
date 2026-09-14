import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

/// The HashCoin mark.
///
/// Bundled rather than fetched: the remote copy misses on a cold cache, which
/// showed up as a loading spinner where the coin should be on first launch.
/// [fallbackUrl] keeps the old remote asset as a safety net.
class HashCoinIcon extends StatelessWidget {
  const HashCoinIcon({required this.size, super.key});

  final double size;

  static const String asset = 'assets/hash_coin.png';
  static const String fallbackUrl =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1754940678/hash_loog_kze6kr.png';
  static const Color _gold = Color(0xFFF4C342);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => CachedNetworkImage(
        imageUrl: fallbackUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, _) =>
            Center(child: RainbowGlowingLoader(size: size / 4)),
        errorWidget: (_, _, _) => Icon(
          Icons.workspace_premium_rounded,
          color: _gold,
          size: size * 0.9,
        ),
      ),
    );
  }
}
