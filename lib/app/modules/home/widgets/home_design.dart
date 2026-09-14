import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design tokens for the home screen.
///
/// Green stays the product accent. Gold is reserved for currency, rewards and
/// streaks, so a gold element anywhere on the page reads as "this is worth
/// something" rather than as decoration.
abstract final class HomeTokens {
  static const Color green = Color(0xFF00DC00);
  static const Color greenBright = Color(0xFF6BFF6B);
  static const Color gold = Color(0xFFF4C342);
  static const Color goldLight = Color(0xFFFFE08A);

  static const Color ink = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF13161E);
  static const Color hairline = Color(0x1AFFFFFF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA7AEBC);
  static const Color textTertiary = Color(0xFF6E7686);

  static const double radius = 22;
  static const double gap = 18;

  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
    color: color,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );

  static TextStyle title(double size) => GoogleFonts.inter(
    color: textPrimary,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static TextStyle body(Color color, {double size = 13}) =>
      GoogleFonts.inter(color: color, fontSize: size, height: 1.4);
}

/// Small letterspaced label that sits above a heading.
class HomeEyebrow extends StatelessWidget {
  const HomeEyebrow(this.label, {this.color = HomeTokens.green, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: HomeTokens.eyebrow(color));
}

/// The standard home card: dark surface, hairline edge, and an optional accent
/// bloom in the top-left so cards read as lit rather than flat.
class HomeCard extends StatelessWidget {
  const HomeCard({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    super.key,
  });

  final Widget child;

  /// When set, tints the card's edge and paints a soft bloom behind it.
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        border: Border.all(
          color: accentColor == null
              ? HomeTokens.hairline
              : accentColor.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        child: Stack(
          children: [
            if (accentColor != null)
              Positioned(
                top: -90,
                left: -40,
                right: -40,
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        child: card,
      ),
    );
  }
}

/// Filled call to action. [gold] switches it to the reward palette; everything
/// else on the page stays green.
class HomeCta extends StatelessWidget {
  const HomeCta({
    required this.label,
    required this.onTap,
    this.icon,
    this.gold = false,
    this.height = 50,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool gold;
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = gold ? HomeTokens.gold : HomeTokens.green;
    final top = gold ? const Color(0xFFFFD467) : HomeTokens.greenBright;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [top, base],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact square action that sits beside a primary CTA. Icon-only, so it
/// carries its label through semantics and a tooltip rather than visibly.
class HomeIconAction extends StatelessWidget {
  const HomeIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(13),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: HomeTokens.hairline),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
