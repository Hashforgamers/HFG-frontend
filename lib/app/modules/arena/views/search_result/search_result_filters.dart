import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// Capsule filter pills: tinted green when selected, iOS fill otherwise.
class SearchResultFilters extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const SearchResultFilters({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  static const _green = Color(0xFF30D158);

  static const _icons = {
    'All': Icons.apps_rounded,
    'Gaming': Icons.sports_esports_rounded,
    'Cafe': Icons.local_cafe_rounded,
    'Nearby': Icons.near_me_rounded,
    'Open Now': Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          final fg = isSelected ? _green : Colors.white;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              Haptics.selection();
              onSelected(filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? _green.withValues(alpha: 0.55)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                color: isSelected
                    ? _green.withValues(alpha: 0.16)
                    : const Color(0x3D767680),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_icons[filter] != null) ...[
                    Icon(_icons[filter], size: 15, color: fg),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    filter,
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
