import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'game_news_controller.dart';

class GamerNewsSection extends StatefulWidget {
  const GamerNewsSection({super.key});

  @override
  State<GamerNewsSection> createState() => _GamerNewsSectionState();
}

class _GamerNewsSectionState extends State<GamerNewsSection>
    with SingleTickerProviderStateMixin {
  final NewsController controller = Get.put(NewsController());

  int currentIndex = 0;
  double dragOffset = 0.0;
  int? slidingOutIndex;
  late AnimationController _slideDownController;

  final List<Map<String, String>> gameNewsCards = [
    {
      'image': "assets/images/gameNews_1.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...',
    },
    {
      'image': "assets/images/gameNews_2.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...',
    },
    {
      'image': "assets/images/gameNews_3.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...',
    },
    {
      'image': "assets/images/gameNews_4.png",
      'title':
          'The Season 4 outro cutscene for Black Ops 6 and Warzone has players once again speculati...',
    },
  ];

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (dragOffset.abs() > 50) {
      if (dragOffset < 0 && currentIndex < gameNewsCards.length - 1) {
        setState(() => slidingOutIndex = currentIndex);
        Future.delayed(const Duration(milliseconds: 160), () {
          setState(() {
            currentIndex++;
            slidingOutIndex = null;
          });
        });
      } else if (dragOffset > 0 && currentIndex > 0) {
        _slideDownController.forward(from: 1.0);
        setState(() => currentIndex--);
      }
    }
    setState(() => dragOffset = 0.0);
  }

  double _getTopOffset(int relativeIndex) {
    double dragEffect = 0.0;
    if (dragOffset > 0 && relativeIndex >= 0) {
      dragEffect = dragOffset / 30;
    } else if (dragOffset < 0) {
      if (relativeIndex == 0) {
        dragEffect = dragOffset / 5;
      } else if (relativeIndex >= 1) {
        dragEffect = dragOffset / 10;
      }
    }
    return 20.0 * relativeIndex + dragEffect;
  }

  double _getHorizontalOffset(int relativeIndex) {
    double cardWidth = 400.0 - (relativeIndex * 30).clamp(0, 80);
    return (400 - cardWidth) / 2;
  }

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
      if (controller.isLoading.value) {
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            itemCount: 3, // 3 shimmer cards
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, __) => _newsShimmerCard(),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GAMER FIREWIRE',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                      children: List.generate(gameNewsCards.length, (i) {
                        int relativeIndex = i - currentIndex;

                        // Only show current and next 2 cards
                        if (relativeIndex < 0 || relativeIndex > 2)
                          return const SizedBox();

                        double topOffset = _getTopOffset(relativeIndex);
                        double horizontalOffset = _getHorizontalOffset(
                          relativeIndex,
                        );
                        double opacity = (1.0 - 0.25 * relativeIndex).clamp(
                          0.0,
                          1.0,
                        );

                        // Smooth slide down effect
                        if (_slideDownController.isAnimating &&
                            relativeIndex == 0) {
                          topOffset -= 30.0 * _slideDownController.value;
                        }

                        Widget card = _buildStackedCard(
                          gameNewsCards[i]['image']!,
                          gameNewsCards[i]['title']!,
                          relativeIndex,
                        );

                        // If it's the one sliding out, wrap in AnimatedSlide
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
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: card,
                          ),
                        );
                      }).reversed.toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStackedCard(String image, String title, int relativeIndex) {
    double baseHeight = 150;
    double baseWidth = 400;
    double height = baseHeight - (relativeIndex * 6).clamp(0, 40);
    double width = baseWidth - (relativeIndex * 30).clamp(0, 80);

    // Scale with drag effect
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
      child: _buildGameNewsCard(image: image, title: title),
    );
  }

  Widget _buildGameNewsCard({required String image, required String title}) {
    return Container(
      height: 150,
      width: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1AFFFFFF), Color(0x1A64BD55)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 150,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            bottom: 15,
            left: 15,
            right: 15,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    image,
                    height: 120,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
