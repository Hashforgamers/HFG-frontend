import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

/// Heading for a home screen section.
///
/// Every section on the page routes through this, so the accent rule and the
/// optional trailing link stay consistent without each section restating them.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.accent,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.accentColor = const Color(0xFF00DC00),
    this.maxLines = 1,
  });

  final String title;

  /// Trailing fragment of the heading, painted in [accentColor].
  final String? accent;

  /// Optional letterspaced label above the heading.
  final String? eyebrow;

  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;
  final int maxLines;

  /// Apple-style section title (like the App Store's "Top Games"):
  /// bold, tight tracking, matching the cards' type.
  static TextStyle style({Color color = Colors.white}) => GoogleFonts.inter(
    color: color,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.6,
  );

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title, style: style()),
            if (accent != null)
              TextSpan(
                text: accent,
                style: style(color: accentColor),
              ),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          HomeEyebrow(eyebrow!, color: accentColor),
          const SizedBox(height: 6),
        ],
        heading,
      ],
    );

    // Without an action this stays intrinsically sized. Callers place it as a
    // plain child of an outer Row (see mini_game_section), and an Expanded in
    // here would demand bounded width that those callers do not provide.
    if (actionLabel == null || onAction == null) return body;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: body),
        const SizedBox(width: 12),
        _Action(
          label: actionLabel!,
          onTap: onAction!,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _sentenceCase(label),
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// "HOST PROGRAM" / "view all" -> "Host program" / "View all".
String _sentenceCase(String s) {
  final t = s.trim().toLowerCase();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
