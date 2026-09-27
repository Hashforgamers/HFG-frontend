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
        height: 44,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: ShapeDecoration(
          shape: ContinuousRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(26)),
            side: BorderSide(
              color: const Color(
                0xFF30D158,
              ).withValues(alpha: isFocused ? .6 : 0),
              width: 1,
            ),
          ),
          color: const Color(0x3D767680),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isFocused
                  ? const Color(0xFF30D158)
                  : const Color(0x99EBEBF5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                cursorColor: const Color(0xFF30D158),
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Search cafe, area or city',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0x99EBEBF5),
                    fontSize: 16,
                  ),
                  isDense: true,
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
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0x99EBEBF5),
                  size: 19,
                ),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
