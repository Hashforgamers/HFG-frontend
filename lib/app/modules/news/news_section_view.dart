import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import 'game_news_controller.dart';

class GamerNewsSection extends StatefulWidget {
  const GamerNewsSection({super.key});

  @override
  State<GamerNewsSection> createState() => _GamerNewsSectionState();
}

class _GamerNewsSectionState extends State<GamerNewsSection>
    with SingleTickerProviderStateMixin {
  final NewsController controller = Get.put(NewsController());
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 200,
          child: Center(
              child: CircularProgressIndicator(
                color: Colors.cyanAccent,
              )),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                  height: 24,
                  width: 24,
                  child: LottieBuilder.asset(
                    'assets/fire.json',
                    height: 24,
                    width: 24,
                    frameRate: FrameRate(60), // Makes animation smoother
                  )),
              const Text(
                ' GAMER FIREWIRE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.newsList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final article = controller.newsList[index];
                return AnimatedBuilder(
                  animation: _animController,
                  builder: (_, __) {
                    return _rainbowCard(
                      title: article.title,
                      deck: article.deck,
                      siteUrl: article.siteUrl,
                      hueRotation: _animController.value,
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _rainbowCard({
    required String title,
    required String deck,
    required String siteUrl,
    required double hueRotation,
  }) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(siteUrl))) {
          await launchUrl(Uri.parse(siteUrl), mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('Error', 'Could not launch article');
        }
      },
      child: Stack(
        children: [
          // Glowing rotating shader layer
          Container(
            width: 320,
            height: 190,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) {
                return SweepGradient(
                  center: Alignment.center,
                  startAngle: 0,
                  endAngle: math.pi * 2,
                  tileMode: TileMode.repeated,
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                  transform: GradientRotation(hueRotation * math.pi * 2),
                ).createShader(rect);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Foreground card content
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    deck,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Divider(
                    color: Colors.cyanAccent,
                    thickness: 0.6,
                    endIndent: 40,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.play_arrow, size: 16, color: Colors.cyanAccent),
                      SizedBox(width: 6),
                      Text(
                        "Read Article",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

}
