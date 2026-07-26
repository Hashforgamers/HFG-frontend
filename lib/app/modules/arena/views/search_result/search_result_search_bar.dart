import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool showClear;

  const SearchResultSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 14, right: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(
              0xff00DC00,
            ).withValues(alpha: isFocused ? .45 : .22),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xff00DC00)),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.inter(color: Colors.white),
                cursorColor: const Color(0xff00DC00),
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Cafe, area or city',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            if (showClear)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
