import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
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
    // brand-gradient rim, as on the other home cards
    return Container(
      padding: const EdgeInsets.all(HomeFrostCard.rim),
      decoration: ShapeDecoration(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(48)),
        ),
        gradient: HomeTokens.brandRim(0.7),
        shadows: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(46)),
          ),
        ),
        child: ColoredBox(
          color: _surface,
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
        ),
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

  Widget _cta() => _SlideToConfirm(
    label: 'Slide to become a host',
    onConfirmed: widget.onTap,
  );
}

/// Slide-to-confirm capsule: drag the knob to the end to continue. A plain
/// tap nudges the knob so the gesture is discoverable.
class _SlideToConfirm extends StatefulWidget {
  const _SlideToConfirm({required this.label, required this.onConfirmed});

  final String label;
  final VoidCallback onConfirmed;

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const _height = 52.0;
  static const _knob = 44.0;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  double _max = 1;
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d) {
    if (_done) return;
    _c.value = (_c.value + d.delta.dx / _max).clamp(0.0, 1.0);
  }

  Future<void> _release([DragEndDetails? _]) async {
    if (_done) return;
    if (_c.value > 0.85) {
      _done = true;
      Haptics.criticalSuccess();
      await _c.animateTo(1, curve: Curves.easeOut);
      widget.onConfirmed();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _done = false;
        _c.animateTo(0, curve: Curves.easeOutCubic);
      }
    } else {
      _c.animateTo(0, curve: Curves.easeOutBack);
    }
  }

  Future<void> _hint() async {
    if (_done) return;
    Haptics.selection();
    await _c.animateTo(0.22, curve: Curves.easeOut);
    if (mounted) _c.animateTo(0, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _max = box.maxWidth - _knob - 8;
        return Semantics(
          button: true,
          label: widget.label,
          onTap: widget.onConfirmed,
          child: GestureDetector(
            onTap: _hint,
            onHorizontalDragUpdate: _drag,
            onHorizontalDragEnd: _release,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final x = _c.value * _max;
                return Container(
                  height: _height,
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        for (final c in HomeTokens.brandGradient.colors)
                          c.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Gradient fill trailing the knob.
                      Container(
                        width: x + _knob + 8,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          gradient: HomeTokens.brandGradient,
                          shadows: [
                            BoxShadow(
                              color: HomeTokens.pink.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: (1 - _c.value * 1.6).clamp(0.0, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.only(left: _knob),
                            child: _Shimmer(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.label,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_double_arrow_right_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4 + x,
                        child: Container(
                          width: _knob,
                          height: _knob,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0B10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            _c.value > 0.85
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A light sweep across the hint text so the track reads as interactive.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(
        colors: const [Color(0x99FFFFFF), Colors.white, Color(0x99FFFFFF)],
        stops: [
          (_c.value - 0.25).clamp(0.0, 1.0),
          _c.value,
          (_c.value + 0.25).clamp(0.0, 1.0),
        ],
      ).createShader(r),
      child: child,
    ),
    child: widget.child,
  );
}
