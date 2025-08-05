import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/cafe_specific_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/global_pass_view.dart';
import 'package:hash/app/modules/game_pass/widgets/game_pass_tab_bar.dart';
import 'package:hash/app/modules/home/views/home_view.dart';

class GamePassView extends StatefulWidget {
  const GamePassView({super.key});

  @override
  State<GamePassView> createState() => _GamePassViewState();
}

class _GamePassViewState extends State<GamePassView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Gaming Pass',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.to(HomeView());
          },
          child: const Icon(Icons.arrow_back, color: Color(0xff00D701)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GamePassTabBar(),
            const SizedBox(height: 30),
            _buildGamePassCard(
              layerImage: 'assets/images/gamepass1.png',
              icon: 'assets/icons/crown.png',
              title: 'Your Global Pass',
              subtitle: 'Use to book at any participating cafe',
              color: Color(0xFF09E6C5),
              linearColor: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF290023),
                  Color(0xFF500037),
                  Color(0xFF500037),
                ],
              ),
              onTap: () {
                Get.to(GlobalPassView());
              },
            ),
            const SizedBox(height: 20),
            _buildGamePassCard(
              layerImage: 'assets/images/gamepass2.png',
              icon: 'assets/icons/controller_robot.png',
              title: 'Cafe-Specific Hash Pass',
              subtitle: 'Book at participating Cafes',
              color: Color(0xFFE6D009),
              linearColor: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5B02A3),
                  Color(0xFF741BE5),
                  Color(0xFF8035F2),
                ],
                stops: [0.0, 0.4, 0.86],
              ),
              onTap: () {
                Get.to(CafeSpecificPassView());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamePassCard({
    required String layerImage,
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required LinearGradient linearColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(25),
          gradient: linearColor,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 4,
              child: SizedBox(
                height: 190,
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  child: Image.asset(
                    layerImage,
                    height: 140,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(icon, height: 26, width: 26),
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
                    subtitle,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                  ),
                  const SizedBox(height: 30),
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
                      'Know More',
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
}
