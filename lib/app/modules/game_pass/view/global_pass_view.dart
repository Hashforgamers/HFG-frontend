import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum GlobalPassCardType { rightImage, leftImage }

class GlobalPassView extends StatefulWidget {
  final TabController tabController;
  const GlobalPassView({super.key, required this.tabController});

  @override
  State<GlobalPassView> createState() => _GlobalPassViewState();
}

class _GlobalPassViewState extends State<GlobalPassView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildLabel(),
        const SizedBox(height: 30),
        _buildGlobalPassCard(
          image: 'assets/images/globalpass1.png',
          icon: 'assets/icons/crown.png',
          title: 'Daily Hash Pass',
          info: '24 Hours @ Rs.500',
          color: Color(0xFFE6D009),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildGlobalPassCard(
          type: GlobalPassCardType.rightImage,
          image: 'assets/images/globalpass2.png',
          icon: 'assets/icons/crown.png',
          title: 'Monthly Hash Pass',
          info: '30 Days @ Rs.1500',
          color: Color(0xFF6DFB60),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildGlobalPassCard(
          image: 'assets/images/globalpass3.png',
          icon: 'assets/icons/crown.png',
          title: 'Yearly Hash Pass',
          info: '365 Days @Rs.4500',
          color: Color(0xFF09E6C5),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildGlobalPassCard({
    GlobalPassCardType type = GlobalPassCardType.leftImage,
    required String image,
    required String icon,
    required String title,
    required String info,
    required Color color,
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
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                image,
                height: 186,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
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
              left: type == GlobalPassCardType.rightImage ? 0 : 24,
              right: type == GlobalPassCardType.rightImage ? 24 : 0,
              child: Column(
                crossAxisAlignment: type == GlobalPassCardType.rightImage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
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
                    info,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'use to book at any cafe',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 20),
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
                      'Buy Pass',
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

  Widget _buildLabel() {
    return Column(
      children: [
        Image.asset('assets/icons/globalPassIcon.png', height: 60, width: 60),
        const SizedBox(height: 8),
        Text(
          'Buy a Global Hash Pass',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
