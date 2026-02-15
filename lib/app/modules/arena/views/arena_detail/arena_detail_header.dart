import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class ArenaDetailHeader extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final double height;

  const ArenaDetailHeader({
    super.key,
    required this.imageUrls,
    required this.onBack,
    required this.onShare,
    this.height = 260,
  });

  @override
  State<ArenaDetailHeader> createState() => _ArenaDetailHeaderState();
}

class _ArenaDetailHeaderState extends State<ArenaDetailHeader> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          if (widget.imageUrls.isEmpty)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.white54,
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 16,
            child: _GlassIconButton(
              icon: Icons.arrow_back,
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: _GlassIconButton(
              icon: Icons.share,
              onPressed: widget.onShare,
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 28,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xff00DC00)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: icon == Icons.share ? 28 : 32,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
