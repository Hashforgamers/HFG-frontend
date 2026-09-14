import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

/// One selectable payment method.
///
/// Rendered as a full-width row rather than a pill: the options used to sit in
/// two rows of `Expanded` chips, so whichever option had no partner stretched
/// to full width and read as more important than the rest. A solid green fill
/// also made the selected option look like a primary button competing with the
/// Pay CTA, so selection is shown with a tint, a border and a check instead.
class BookingSummaryPaymentOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const BookingSummaryPaymentOptionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = HomeTokens.green;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected
            ? accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: 0.55)
                    : HomeTokens.hairline,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? accent : HomeTokens.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : HomeTokens.textSecondary,
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Indicator(isSelected: isSelected, accent: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.isSelected, required this.accent});

  final bool isSelected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? accent : Colors.transparent,
        border: Border.all(
          color: isSelected ? accent : Colors.white.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
          : null,
    );
  }
}
