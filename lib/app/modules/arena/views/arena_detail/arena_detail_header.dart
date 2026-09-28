import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

/// Full-bleed cafe hero: swipeable photos that fade into the page, with the
/// cafe's name, live status and address laid over the bottom edge — the same
/// "photo + overlay" treatment as the home cafe cards.
class ArenaDetailHeader extends StatefulWidget {
  const ArenaDetailHeader({
    super.key,
    required this.imageUrls,
    required this.onBack,
    required this.onShare,
    required this.title,
    required this.address,
    this.isOpen,
    this.height = 360,
  });

  final List<String> imageUrls;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final String title;
  final String address;
  /// Null while the shop status is still loading; the pill is hidden then.
  final bool? isOpen;
  final double height;

  @override
  State<ArenaDetailHeader> createState() => _ArenaDetailHeaderState();
}

class _ArenaDetailHeaderState extends State<ArenaDetailHeader> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _hasAddress {
    final a = widget.address.trim().toLowerCase();
    return a.isNotEmpty && a != 'address not available';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final images = widget.imageUrls.where((u) => u.trim().isNotEmpty).toList();

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const _HeroPlaceholder()
          else
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => const _HeroPlaceholder(),
              ),
            ),
          // Top scrim keeps the glass buttons legible on bright photos.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Bottom fade melts the photo into the black page.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.55, 1],
                    colors: [
                      Colors.transparent,
                      Color(0xCC000000),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 10,
            left: 16,
            child: _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            top: topInset + 10,
            right: 16,
            child: _GlassIconButton(
              icon: Icons.ios_share_rounded,
              label: 'Share cafe',
              onPressed: widget.onShare,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.isOpen != null)
                      _StatusPill(isOpen: widget.isOpen!),
                    const Spacer(),
                    if (images.length > 1)
                      _PageDots(count: images.length, index: _currentPage),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HomeTokens.title(30),
                ),
                if (_hasAddress) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: HomeTokens.green,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeTokens.body(HomeTokens.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13161E), Color(0xFF07140A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 56,
          color: HomeTokens.green,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? HomeTokens.green : const Color(0xFFFF5252);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                isOpen ? 'Open now' : 'Closed',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(left: 4),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? HomeTokens.green : Colors.white30,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.black.withValues(alpha: 0.35),
            child: InkWell(
              onTap: onPressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
