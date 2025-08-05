import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/cafe_specific_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/global_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/hash_pass_history_view.dart';

class GamePassTabBar extends StatelessWidget {
  final String? currentPage;
  const GamePassTabBar({super.key, this.currentPage = 'home'});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTextButton(
          label: 'Global',
          isSelected: currentPage == 'global',
          onTap: () {
            if (currentPage != 'global') {
              Get.to(GlobalPassView());
            }
          },
        ),
        _buildTextButton(
          label: 'Cafe-Specific',
          isSelected: currentPage == 'cafe',
          onTap: () {
            if (currentPage != 'cafe') {
              Get.to(CafeSpecificPassView());
            }
          },
        ),
        _buildTextButton(
          label: 'History',
          isSelected: currentPage == 'history',
          onTap: () {
            if (currentPage != 'history') {
              Get.to(HashPassHistoryView());
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Color(0xFF338125) : Color(0xFF505050),
          fontSize: 16,
        ),
      ),
    );
  }
}
