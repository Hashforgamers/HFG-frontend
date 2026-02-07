import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool showClear;

  const SearchResultSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xff338125).withValues(alpha: .2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xff338125)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: const Color(0xff338125),
                    decoration: InputDecoration(
                      hintText: 'Search gaming centers, cafes...',
                      hintStyle: GoogleFonts.inter(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
                if (showClear)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
