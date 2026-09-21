import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Booking flow design system ("Elevated Dark").
///
/// A single, consistent visual language for the entire cafe booking flow:
/// slot selection → summary/payment → success. Every screen in the flow should
/// build on these tokens and components instead of hand-rolling colours,
/// spacing and cards so the experience reads as one system.
///
/// Design principles (Apple HIG — clarity, deference, depth):
///  • Deference: content over chrome. Deep, calm layered surfaces; hairline
///    borders that whisper rather than shout; restrained, purposeful colour.
///  • Clarity: a precise type hierarchy, generous negative space and legible
///    contrast. HUD-like numerals give price/score a subtle gaming charge.
///  • Depth: translucency (blurred bars) and soft elevation convey layering
///    without heavy outlines.
///  • Green (`accent`) is the single brand accent — primary actions, the
///    active/selected state and positive signals all share one green. Amber
///    is for warnings and red is reserved strictly for errors, never décor.
/// ─────────────────────────────────────────────────────────────────────────
class BookingColors {
  BookingColors._();

  // Base backgrounds (dark → light as elevation increases). Near-black with a
  // faint cool cast; calm and deferential so content and the green accent read.
  static const Color bg = Color(0xFF070809);
  static const Color bgElevated = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF121419);
  static const Color surfaceAlt = Color(0xFF181B21);
  static const Color surfaceHigh = Color(0xFF20242C);

  // Borders / hairlines — deliberately quiet (Apple deference).
  static const Color border = Color(0xFF20242B);
  static const Color borderSoft = Color(0xFF17191F);
  static const Color borderStrong = Color(0xFF2C313A);

  // Brand accent (the app's established green) + gradient stops. One green for
  // the whole flow: primary actions, selection and positive signals.
  static const Color accent = Color(0xFF00DC00);
  static const Color accentBright = Color(0xFF6BFF6B);
  static const Color accentDim = Color(0xFF0C2A12);

  // Semantic — success shares the brand green; warning amber; danger red only.
  static const Color success = Color(0xFF00DC00);
  static const Color successDim = Color(0xFF0C2A12);
  static const Color warning = Color(0xFFF5A524);
  static const Color warningDim = Color(0xFF33280F);
  static const Color danger = Color(0xFFF0524B);
  static const Color dangerDim = Color(0xFF331615);

  // Text.
  static const Color textPrimary = Color(0xFFF3F5F4);
  static const Color textSecondary = Color(0xFF9CA3A0);
  static const Color textMuted = Color(0xFF61666A);
  static const Color textOnAccent = Color(0xFF06130B);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBright, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [accentBright, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing scale (4-point grid).
class BookingSpacing {
  BookingSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner radii.
class BookingRadius {
  BookingRadius._();
  static const double chip = 10;
  static const double card = 18;
  static const double button = 14;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Typography helpers — the whole flow standardises on Inter.
class BookingText {
  BookingText._();

  static TextStyle display(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textPrimary,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle title(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle sectionLabel(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textPrimary,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static TextStyle secondary(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textSecondary,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static TextStyle muted(BuildContext context) => GoogleFonts.inter(
    color: BookingColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

/// Ambient radial glow used behind hero areas of the flow.
class BookingAmbientGlow extends StatelessWidget {
  const BookingAmbientGlow({
    super.key,
    this.color = BookingColors.accent,
    this.alignment = const Alignment(1.1, -1.0),
    this.size = 320,
    this.opacity = 0.18,
  });

  final Color color;
  final Alignment alignment;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard scaffold for every booking-flow screen: layered background with an
/// optional ambient glow and a consistent, minimal app bar.
class BookingScaffold extends StatelessWidget {
  const BookingScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.bottomBar,
    this.showBack = true,
    this.onBack,
    this.glow = true,
    this.glowColor = BookingColors.accent,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBack;
  final VoidCallback? onBack;
  final bool glow;
  final Color glowColor;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookingColors.bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: showBack ? 0 : BookingSpacing.lg,
        leading: showBack
            ? IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: BookingColors.textPrimary,
              )
            : null,
        title:
            titleWidget ??
            (title == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: GoogleFonts.inter(
                          color: BookingColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty)
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            color: BookingColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  )),
        actions: actions,
      ),
      body: Stack(
        children: [
          if (glow)
            BookingAmbientGlow(color: glowColor.withValues(alpha: 1)),
          body,
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Elevated surface card. The core building block for grouped content.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BookingSpacing.lg),
    this.margin,
    this.color = BookingColors.surface,
    this.borderColor = BookingColors.border,
    this.radius = BookingRadius.card,
    this.onTap,
    this.highlight = false,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool highlight;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlight ? BookingColors.accent : borderColor,
          width: highlight ? 1.4 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: BookingColors.accent.withValues(alpha: 0.16),
                  blurRadius: 22,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!.call();
        },
        child: content,
      ),
    );
  }
}

/// Section header — an uppercase label with an optional trailing widget, used
/// to introduce grouped content across the flow.
class BookingSectionHeader extends StatelessWidget {
  const BookingSectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      BookingSpacing.xs,
      0,
      BookingSpacing.xs,
      BookingSpacing.md,
    ),
  });

  final String label;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: BookingColors.textSecondary),
            const SizedBox(width: BookingSpacing.sm),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: BookingText.sectionLabel(context),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small status pill (available / sold out / expired / discount, etc).
enum BookingPillTone { neutral, success, warning, danger, accent }

class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill({
    super.key,
    required this.label,
    this.tone = BookingPillTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final BookingPillTone tone;
  final IconData? icon;
  final bool dense;

  Color get _fg => switch (tone) {
    BookingPillTone.success => BookingColors.success,
    BookingPillTone.warning => BookingColors.warning,
    BookingPillTone.danger => BookingColors.danger,
    BookingPillTone.accent => BookingColors.accentBright,
    BookingPillTone.neutral => BookingColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BookingRadius.pill),
        border: Border.all(color: _fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: _fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: _fg,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary call-to-action button with gradient fill, loading and disabled
/// states. Used for every "proceed / pay / continue" action in the flow.
class BookingPrimaryButton extends StatelessWidget {
  const BookingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.gradient,
    this.height = 54,
    this.trailingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final Gradient? gradient;
  final double height;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !loading && onPressed != null;
    return Semantics(
      button: true,
      enabled: isActive,
      label: loading ? '$label, please wait' : label,
      child: Opacity(
      opacity: isActive ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(BookingRadius.button),
          onTap: isActive
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed!.call();
                }
              : null,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: isActive
                  ? (gradient ?? BookingColors.accentGradient)
                  : null,
              color: isActive ? null : BookingColors.surfaceHigh,
              borderRadius: BorderRadius.circular(BookingRadius.button),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: BookingColors.accent.withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: -8,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: BookingColors.textOnAccent,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 19,
                            color: isActive
                                ? BookingColors.textOnAccent
                                : BookingColors.textMuted,
                          ),
                          const SizedBox(width: BookingSpacing.sm),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: isActive
                                ? BookingColors.textOnAccent
                                : BookingColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (trailingLabel != null) ...[
                          const SizedBox(width: BookingSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BookingColors.textOnAccent.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trailingLabel!,
                              style: GoogleFonts.inter(
                                color: BookingColors.textOnAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Secondary / outlined action button.
class BookingSecondaryButton extends StatelessWidget {
  const BookingSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!.call();
              },
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, size: 18, color: BookingColors.textPrimary),
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: BookingColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: BookingColors.surfaceAlt,
          side: const BorderSide(color: BookingColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BookingRadius.button),
          ),
        ),
      ),
    );
  }
}

/// Sticky bottom action bar container used across the flow (blurred, layered).
class BookingBottomBar extends StatelessWidget {
  const BookingBottomBar({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: BookingColors.bgElevated.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: BookingColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.fromLTRB(
                    BookingSpacing.lg,
                    BookingSpacing.md,
                    BookingSpacing.lg,
                    BookingSpacing.md,
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal step indicator for the flow: Slots → Summary → Done.
class BookingStepIndicator extends StatelessWidget {
  const BookingStepIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _dot(i),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: i < currentIndex
                      ? BookingColors.accent
                      : BookingColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _dot(int i) {
    final done = i < currentIndex;
    final active = i == currentIndex;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (done || active)
                ? BookingColors.accent
                : BookingColors.surfaceHigh,
            border: Border.all(
              color: active
                  ? BookingColors.accentBright
                  : (done ? BookingColors.accent : BookingColors.borderStrong),
            ),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: BookingColors.textOnAccent,
                )
              : Center(
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      color: active
                          ? BookingColors.textOnAccent
                          : BookingColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          steps[i],
          style: GoogleFonts.inter(
            color: (done || active)
                ? BookingColors.textPrimary
                : BookingColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Empty / error state block reused by the flow.
class BookingEmptyState extends StatelessWidget {
  const BookingEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = BookingPillTone.danger,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String message;
  final BookingPillTone tone;
  final Widget? footnote;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BookingPillTone.success => BookingColors.success,
      BookingPillTone.warning => BookingColors.warning,
      BookingPillTone.danger => BookingColors.danger,
      BookingPillTone.accent => BookingColors.accent,
      BookingPillTone.neutral => BookingColors.textSecondary,
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BookingSpacing.xxl),
        child: BookingCard(
          padding: const EdgeInsets.symmetric(
            horizontal: BookingSpacing.xxl,
            vertical: BookingSpacing.xxxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: BookingSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: BookingColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BookingSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: BookingText.secondary(context),
              ),
              if (footnote != null) ...[
                const SizedBox(height: BookingSpacing.lg),
                footnote!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
