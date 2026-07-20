import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class ArenaDetailHeader extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final double height;
  final String title;

  const ArenaDetailHeader({
    super.key,
    required this.imageUrls,
    required this.onBack,
    required this.onShare,
    required this.title,
    this.height = 210,
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF181818), Color(0xFF0B160D)],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00DC00).withValues(alpha: .10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00DC00).withValues(alpha: .22),
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 28,
                      color: Color(0xFF00DC00),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                  color: const Color(0xFF151515),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    size: 42,
                    color: Color(0xFF00DC00),
                  ),
                ),
              ),
            ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0F0F0F)],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            child: _GlassIconButton(
              icon: Icons.arrow_back,
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
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

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: icon == Icons.share ? 22 : 25,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
