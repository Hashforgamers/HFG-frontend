import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for Hash Live.
///
/// Red is Hash Live's identity and is kept deliberately distinct from Hash
/// Hub's green - it reads as "broadcast". Typography, spacing and card shapes
/// otherwise mirror the Hub side so the two halves feel like one app.
///
/// Type is Inter throughout. Orbitron was previously used for headings and for
/// the host's follower/stream counts, but it is not bundled and `google_fonts`
/// fetches at runtime, so whenever that fetch failed those numerals rendered as
/// missing-glyph boxes.
class LiveUi {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0C0E13);
  static const Color surface = Color(0xFF15171C);
  static const Color surfaceSoft = Color(0xFF20232A);
  static const Color stroke = Color(0xFF292D35);
  static const Color accent = Color(0xFFFF3D4D);
  static const Color accentSoft = Color(0xFFFF6673);
  static const Color softText = Color(0xFF989EAA);

  static const Color hairline = Color(0x1AFFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA7AEBC);
  static const Color textTertiary = Color(0xFF6E7686);

  static const double radiusLg = 22;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  // ── Type ──────────────────────────────────────────────────────────────────
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
    color: color,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );

  static TextStyle heading(double size) => GoogleFonts.inter(
    color: textPrimary,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.4,
  );

  /// Counts and metrics. Tabular figures keep columns of numbers aligned.
  static TextStyle numeral(double size) => GoogleFonts.inter(
    color: textPrimary,
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
  );

  static TextStyle title = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle body = GoogleFonts.inter(color: softText, fontSize: 12);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({double radius = radiusMd}) =>
      BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1E24), Color(0xFF14161B)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration pageDecoration() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF111318), Color(0xFF090A0D)],
    ),
  );

  static InputDecoration input({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9EA5B5), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF242934),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF363C48)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF363C48)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accentSoft, width: 1.1),
    ),
  );
}

/// Small letterspaced label above a heading.
class LiveEyebrow extends StatelessWidget {
  const LiveEyebrow(this.label, {this.color = LiveUi.accentSoft, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: LiveUi.eyebrow(color));
}

/// Section heading with an optional count/trailing action, so every section in
/// Hash Live is titled the same way.
class LiveSectionTitle extends StatelessWidget {
  const LiveSectionTitle(
    this.title, {
    this.trailing,
    this.onTrailingTap,
    super.key,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final label = trailing;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: LiveUi.heading(19)),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 12),
          if (onTrailingTap == null)
            Text(label, style: LiveUi.eyebrow(LiveUi.textTertiary))
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTrailingTap,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: LiveUi.eyebrow(LiveUi.accentSoft)),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: LiveUi.accentSoft,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Standard Hash Live card: dark surface, hairline edge, optional accent bloom.
class LiveCard extends StatelessWidget {
  const LiveCard({
    required this.child,
    this.accent = false,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });

  final Widget child;
  final bool accent;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: LiveUi.surface,
        borderRadius: BorderRadius.circular(LiveUi.radiusLg),
        border: Border.all(
          color: accent
              ? LiveUi.accent.withValues(alpha: 0.28)
              : LiveUi.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LiveUi.radiusLg),
        child: Stack(
          children: [
            if (accent)
              Positioned(
                top: -90,
                left: -40,
                right: -40,
                height: 210,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        LiveUi.accent.withValues(alpha: 0.18),
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
        borderRadius: BorderRadius.circular(LiveUi.radiusLg),
        child: card,
      ),
    );
  }
}

/// Primary action. Red is the only fill colour used for CTAs in Hash Live.
class LiveCta extends StatelessWidget {
  const LiveCta({
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 50,
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: active
                ? const LinearGradient(
                    colors: [LiveUi.accentSoft, LiveUi.accent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.07),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: LiveUi.accent.withValues(alpha: 0.34),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: active ? onTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 19,
                              color: active ? Colors.white : LiveUi.textTertiary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: active
                                    ? Colors.white
                                    : LiveUi.textTertiary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
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

/// Pulsing LIVE badge. The pulse is what separates "live right now" from a
/// static red label.
class LivePill extends StatefulWidget {
  const LivePill({this.label = 'LIVE', this.compact = false, super.key});

  final String label;
  final bool compact;

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 20.0 : 24.0;
    return Semantics(
      label: 'Live now',
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 7 : 9),
        decoration: BoxDecoration(
          color: LiveUi.accent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: LiveUi.accent.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.45 + 0.55 * _c.value,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: widget.compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state with an optional action, replacing the bare "Nothing yet" rows.
class LiveEmptyState extends StatelessWidget {
  const LiveEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final body = message;
    final action = actionLabel;
    return LiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: LiveUi.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: LiveUi.accentSoft, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: LiveUi.heading(15),
          ),
          if (body != null) ...[
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: LiveUi.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: 16),
            LiveCta(label: action, onTap: onAction!, height: 44),
          ],
        ],
      ),
    );
  }
}

/// Metric tile used on the host dashboard.
class LiveStatTile extends StatelessWidget {
  const LiveStatTile({
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(LiveUi.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LiveUi.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LiveUi.radiusMd),
            border: Border.all(color: LiveUi.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: LiveUi.accentSoft),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LiveUi.eyebrow(LiveUi.textTertiary),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: LiveUi.textTertiary,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: LiveUi.numeral(22)),
            ],
          ),
        ),
      ),
    );
  }
}
