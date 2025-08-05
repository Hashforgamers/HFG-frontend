import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/game_pass/widgets/game_pass_tab_bar.dart';

class CafeSpecificPassView extends StatefulWidget {
  const CafeSpecificPassView({super.key});

  @override
  State<CafeSpecificPassView> createState() => _CafeSpecificPassViewState();
}

class _CafeSpecificPassViewState extends State<CafeSpecificPassView> {
  final List<Map<String, String>> cafeList = [
    {
      'image': 'assets/images/cafepass1.png',
      'title': 'Retro Gaming Studio',
      'distance': '1.3 km',
    },
    {
      'image': 'assets/images/cafepass2.png',
      'title': 'Dragon Gaming Cafe',
      'distance': '1.3 km',
    },
    {
      'image': 'assets/images/cafepass3.png',
      'title': 'Retro Gaming Studio',
      'distance': '1.3 km',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GamePassTabBar(currentPage: 'cafe'),
                  const SizedBox(height: 30),
                  _buildLabel(),
                  ListView.separated(
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: cafeList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final cafe = cafeList[index];
                      return _buildCafePassCard(context, cafe);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _buildCafePassCard(
    BuildContext context,
    Map<String, String> cafe,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                cafe['image']!,
                height: 200,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cafe['title']!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const SizedBox(width: 12),
                                Row(
                                  children: List.generate(
                                    4,
                                    (index) => const Icon(
                                      Icons.star,
                                      color: Color(0xFFE6D009),
                                      size: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cafe['distance']!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 13),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          height: 36,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Color(0xFFDADADA),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Buy Pass',
                              style: GoogleFonts.inter(
                                color: Color(0xFFDADADA),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      pinned: false,
      leading: GestureDetector(
        onTap: () {
          Get.to(GamePassView());
        },
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        'Cafe-Specific Pass',
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildLabel() {
    return Column(
      children: [
        Image.asset('assets/icons/cafePassIcon.png', height: 50, width: 50),
        const SizedBox(height: 8),
        Text(
          'All Participating Cafes',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }
}
