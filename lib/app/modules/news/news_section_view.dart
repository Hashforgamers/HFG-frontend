import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/widgets/loader.dart';
import 'game_news_controller.dart';

class GamerNewsSection extends StatefulWidget {
  const GamerNewsSection({super.key});

  @override
  State<GamerNewsSection> createState() => _GamerNewsSectionState();
}

class _GamerNewsSectionState extends State<GamerNewsSection>
    with SingleTickerProviderStateMixin {
  final NewsController controller = Get.put(NewsController(), permanent: true);

  int currentIndex = 0;
  double dragOffset = 0.0;
  int? slidingOutIndex;
  late AnimationController _slideDownController;

  @override
  void initState() {
    super.initState();
    _slideDownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _slideDownController.dispose();
    super.dispose();
  }

  // ──────────────── Drag handlers ────────────────
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() => dragOffset += details.delta.dy);
  }

  void _handleDragEnd(DragEndDetails details) {
    final total = controller.items.length;
    if (dragOffset.abs() > 50) {
      if (dragOffset < 0 && currentIndex < total - 1) {
        // Swipe up → next
        Haptics.navigation();
        setState(() => slidingOutIndex = currentIndex);
        Future.delayed(const Duration(milliseconds: 160), () {
          setState(() {
            currentIndex++;
            slidingOutIndex = null;
          });
          _maybeLoadMore();
          _prefetchCover(currentIndex + 1);
          _prefetchCover(currentIndex + 2);
        });
      } else if (dragOffset > 0 && currentIndex > 0) {
        // Swipe down → previous
        Haptics.selection();
        _slideDownController.forward(from: 1.0);
        setState(() => currentIndex--);
        _prefetchCover(currentIndex + 1);
      }
    }
    setState(() => dragOffset = 0.0);
  }


  void _maybeLoadMore() {
    // When we are within last 4 cards, trigger loadMore
    final total = controller.items.length;
    if (controller.hasMore && currentIndex >= total - 4) {
      controller.loadMore();
    }
  }

  void _prefetchCover(int idx) {
    if (!mounted) return;
    final list = controller.items;
    if (idx < 0 || idx >= list.length) return;
    final url = list[idx].imageUrl;
    if (url == null || url.isEmpty) return;
    precacheImage(CachedNetworkImageProvider(url), context);
  }

  // ──────────────── Layout helpers ────────────────
  double _getTopOffset(int relativeIndex) {
    double dragEffect = 0.0;
    if (dragOffset > 0 && relativeIndex >= 0) {
      dragEffect = dragOffset / 30;
    } else if (dragOffset < 0) {
      if (relativeIndex == 0) dragEffect = dragOffset / 5;
      else if (relativeIndex >= 1) dragEffect = dragOffset / 10;
    }
    return 20.0 * relativeIndex + dragEffect;
  }

  double _getHorizontalOffset(int relativeIndex) {
    final cardWidth = 400.0 - (relativeIndex * 30).clamp(0, 80);
    return (400 - cardWidth) / 2;
  }

  // ──────────────── UI ────────────────
  Widget _newsShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: 320,
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, __) => _newsShimmerCard(),
          ),
        );
      }

      if (controller.items.isEmpty) {
        return const SizedBox.shrink();
      }

      final list = controller.items;

      // Cap currentIndex within bounds after updates
      if (currentIndex >= list.length) currentIndex = list.length - 1;
      if (currentIndex < 0) currentIndex = 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GAMER FIREWIRE',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: SizedBox(
                width: 400,
                height: 170,
                child: AnimatedBuilder(
                  animation: _slideDownController,
                  builder: (context, _) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(list.length, (i) {
                        final relativeIndex = i - currentIndex;

                        // Only show current and next 2 (cheap)
                        if (relativeIndex < 0 || relativeIndex > 2) {
                          return const SizedBox.shrink();
                        }

                        double topOffset = _getTopOffset(relativeIndex);
                        double horizontalOffset = _getHorizontalOffset(relativeIndex);
                        double opacity = (1.0 - 0.25 * relativeIndex).clamp(0.0, 1.0);

                        if (_slideDownController.isAnimating && relativeIndex == 0) {
                          topOffset -= 30.0 * _slideDownController.value;
                        }

                        Widget card = RepaintBoundary(
                          child: _buildStackedCard(list[i], relativeIndex),
                        );

                        if (i == slidingOutIndex) {
                          card = AnimatedSlide(
                            duration: const Duration(milliseconds: 160),
                            offset: const Offset(0, -0.76),
                            child: card,
                          );
                        }

                        return Positioned(
                          top: topOffset,
                          left: horizontalOffset,
                          right: horizontalOffset,
                          child: Opacity(opacity: opacity, child: card),
                        );
                      }).reversed.toList(),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tiny loading hint when fetching more
          if (controller.isLoading.value && controller.items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  height: 16, width: 16,
                  child: const AppLinearLoader(),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildStackedCard(GameNewsItem item, int relativeIndex) {
    const baseHeight = 150.0;
    const baseWidth = 400.0;
    final height = baseHeight - (relativeIndex * 6).clamp(0, 40);
    final width = baseWidth - (relativeIndex * 30).clamp(0, 80);

    double scale = 1.0;
    if (relativeIndex == 0 && dragOffset > 0) {
      scale = 1.02 - (dragOffset / 1000).clamp(0, 0.02);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      height: height,
      width: width,
      transform: Matrix4.identity()..scale(scale),
      child: _buildGameNewsCard(item: item),
    );
  }

  Widget _buildGameNewsCard({required GameNewsItem item}) {
    final accent = const Color(0xff00DC00);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        if (item.url.isEmpty) return;
        final uri = Uri.parse(item.url);
                if (await canLaunchUrl(uri)) {
                  Haptics.selection();
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
      child: Container(
        height: 150,
        width: 400,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x1AFFFFFF), Color(0x1A00DC00)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Frosted panel (smaller blur for perf)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: 15, bottom: 15, left: 15, right: 15,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: item.imageUrl == null
                        ? Container(
                      height: 120, width: 150,
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.image, color: Colors.white24),
                    )
                        : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      height: 120, width: 150, fit: BoxFit.cover,
                      memCacheWidth: 300, // lightweight caching
                      placeholder: (_, __) =>
                      const Center(child: RainbowGlowingLoader(size: 24)),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white54, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item.title,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                          maxLines: 3, overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Source + time
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.source ?? 'Gaming',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ago(item.publishedAt),
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white54),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 16, color: accent.withOpacity(0.9)),
                          ],
                        ),
                      ],
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

  String _ago(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
