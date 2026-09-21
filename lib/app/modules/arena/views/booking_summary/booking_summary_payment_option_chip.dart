import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';

/// One selectable payment method, rendered as a full-width row.
///
/// Selection is shown with an accent tint, border and a check indicator (not a
/// solid fill) so the chosen option never competes visually with the primary
/// Pay CTA at the bottom of the screen.
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
    const accent = BookingColors.accent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected
            ? accent.withValues(alpha: 0.10)
            : BookingColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? BookingColors.accentBright
                    : BookingColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? BookingColors.accentBright
                      : BookingColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? BookingColors.textPrimary
                          : BookingColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Indicator(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? BookingColors.accent : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? BookingColors.accentBright
              : BookingColors.borderStrong,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: BookingColors.textOnAccent,
            )
          : null,
    );
  }
}
