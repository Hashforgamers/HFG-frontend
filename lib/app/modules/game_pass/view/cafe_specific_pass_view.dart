import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CafeSpecificPassView extends StatefulWidget {
  final TabController tabController;
  const CafeSpecificPassView({super.key, required this.tabController});

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
    return ListView(
      children: [
        _buildLabel(),
        const SizedBox(height: 30),
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
