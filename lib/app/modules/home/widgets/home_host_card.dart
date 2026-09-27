import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// Tournament host-program card: hero artwork (headline baked in), a native
/// four-feature panel and a pink "Become a Tournament Host" capsule.
class HomeHostCard extends StatefulWidget {
  const HomeHostCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<HomeHostCard> createState() => _HomeHostCardState();
}

class _HomeHostCardState extends State<HomeHostCard> {
  static const _heroAsset = 'assets/host_program_hero.jpg';
  static const _heroAspect = 1388 / 583;
  static const _surface = Color(0xFF121216);
  static const _separator = Color(0x26FFFFFF);
  static const _green = Color(0xFF30D158);
  static const _greenDeep = Color(0xFF1E9E3E);

  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  void _open() {
    Haptics.selection();
    widget.onTap();
  }

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 15 ? -0.3 : -0.1,
        height: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(48)),
          side: BorderSide(color: Color(0x5900DC00), width: 0.8),
        ),
        color: _surface,
        shadows: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _open,
            child: AspectRatio(
              aspectRatio: _heroAspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _heroAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A1F5C), Color(0xFFB24A8F)],
                        ),
                      ),
                    ),
                  ),
                  // Blend the art into the card surface below it.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00121216), Color(0xFF121216)],
                        stops: [0.93, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_features(), const SizedBox(height: 8), _cta()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _features() {
    const items = [
      (
        Icons.emoji_events_rounded,
        Color(0xFF30D158),
        'Set Your Rules',
        'Game, format, prizes',
      ),
      (
        Icons.groups_rounded,
        Color(0xFF7D7AFF),
        'Bring Your Players',
        'Build your community',
      ),
      (
        Icons.calendar_month_rounded,
        Color(0xFFFF9F0A),
        'Manage & Host',
        'Registrations, brackets',
      ),
      (
        Icons.bar_chart_rounded,
        Color(0xFFFF375F),
        'Grow & Earn',
        'More visibility for your café',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: const ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(34)),
          side: BorderSide(color: _separator, width: 0.5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E23), Color(0xFF16161A)],
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: _separator,
                ),
              Expanded(child: _feature(item.$1, item.$2, item.$3, item.$4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, Color color, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                side: BorderSide(
                  color: color.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.42),
                  color.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: _text(10, Colors.white, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _open,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5CE07A), _green, _greenDeep],
              stops: [0, 0.5, 1],
            ),
            shadows: [
              BoxShadow(
                color: _green.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0B10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Expanded(
                child: Text(
                  'Become a Tournament Host',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
