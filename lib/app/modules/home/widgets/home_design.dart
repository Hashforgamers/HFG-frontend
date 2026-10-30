import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design tokens for the home screen.
///
/// The pink-to-orange brand gradient is the home accent; green is kept as a
/// hint (live dots, subtle tints). Gold is reserved for currency, rewards and
/// streaks, so a gold element anywhere on the page reads as "this is worth
/// something" rather than as decoration.
abstract final class HomeTokens {
  static const Color green = Color(0xFF00DC00);
  static const Color greenBright = Color(0xFF6BFF6B);
  static const Color gold = Color(0xFFF4C342);
  static const Color goldLight = Color(0xFFFFE08A);

  /// hashforgamers.com "BOOK. WIN." palette: the home accent and primary actions.
  static const Color pink = Color(0xFFFF3E8E);
  static const Color coral = Color(0xFFFF6F61);
  static const Color orange = Color(0xFFFF9A3D);
  static const LinearGradient brandGradient = LinearGradient(
    colors: [pink, coral, orange],
  );

  /// Card rim: the brand gradient, faded so it frames rather than shouts.
  static LinearGradient brandRim([double alpha = 0.55]) => LinearGradient(
    colors: [for (final c in brandGradient.colors) c.withValues(alpha: alpha)],
  );

  /// Frosted pane laid over an 18px backdrop blur (chat button, Hash Hub).
  static const LinearGradient frost = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x59000000)],
  );

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
  const HomeEyebrow(this.label, {this.color = HomeTokens.coral, super.key});

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

/// The home card surface: a thin brand-gradient rim around frosted glass, the
/// same build as the chat button and the Hash Hub / Hash Live cards.
class HomeFrostCard extends StatelessWidget {
  const HomeFrostCard({
    super.key,
    required this.child,
    this.radius = HomeTokens.radius,
    this.padding = EdgeInsets.zero,
    this.rimAlpha = 0.55,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double rimAlpha;

  static const double rim = 1.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: HomeTokens.brandRim(rimAlpha),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(rim),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - rim),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: HomeTokens.frost),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action pill in the brand gradient.
class HomeBrandButton extends StatelessWidget {
  const HomeBrandButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 34,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height * 0.53),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          gradient: HomeTokens.brandGradient,
          shadows: [
            BoxShadow(
              color: HomeTokens.pink.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
