import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_coin/widgets/hash_coin_icon.dart';
import 'package:hash/core/utils/haptics.dart';

/// The daily login reward moment.
///
/// The coins are already credited by the time this appears, so the dialog's job
/// is to make the reward land rather than to gate it: nothing here can fail, and
/// dismissing it never costs the user anything.
class DailyLoginRewardDialog extends StatefulWidget {
  const DailyLoginRewardDialog({
    required this.amount,
    this.streak = 1,
    super.key,
  });

  final int amount;

  /// Consecutive days claimed, including today. Drives the progress row.
  final int streak;

  static const Color accent = Color(0xFF37EBF3);
  static const Color gold = Color(0xFFF4C342);
  static const Color goldLight = Color(0xFFFFE08A);
  static const Color surface = Color(0xFF0E1016);

  /// A week reads as a complete, attainable run at a glance.
  static const int streakTarget = 7;

  @override
  State<DailyLoginRewardDialog> createState() => _DailyLoginRewardDialogState();
}

class _DailyLoginRewardDialogState extends State<DailyLoginRewardDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// One-shot sparkle burst behind the coin, fired once the card has settled.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Slow breathing glow. The coin artwork carries its own specular
  /// highlights, so anything drawn on the rim competes with it - this sits
  /// behind the coin instead.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// Fast, irregular flicker that gives the streak flame its living, dancing
  /// quality and drives the today-segment glow.
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.9, end: 1)
      .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutBack));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<int> _count = IntTween(begin: 0, end: widget.amount)
      .animate(
        CurvedAnimation(
          parent: _entry,
          curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
        ),
      );

  int get _filledDays =>
      widget.streak.clamp(0, DailyLoginRewardDialog.streakTarget);

  @override
  void initState() {
    super.initState();
    _entry.forward();
    _pulse.repeat(reverse: true);
    _flicker.repeat(reverse: true);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _burst.forward();
      Haptics.success();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _burst.dispose();
    _pulse.dispose();
    _flicker.dispose();
    super.dispose();
  }

  void _claim() {
    Haptics.cta();
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Semantics(
            container: true,
            label:
                'Daily login reward. You received ${widget.amount} HashCoins. '
                'Day ${widget.streak} streak.',
            child: _card(),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 372),
          decoration: BoxDecoration(
            color: DailyLoginRewardDialog.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: DailyLoginRewardDialog.gold.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Warm aurora bleeding down from behind the coin.
              Positioned(
                top: -70,
                left: 0,
                right: 0,
                height: 320,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        DailyLoginRewardDialog.gold.withValues(alpha: 0.20),
                        DailyLoginRewardDialog.accent.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.5, 0.95],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                // Large text scales push this past short viewports, so the
                // content scrolls rather than overflowing.
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _eyebrow(),
                      const SizedBox(height: 18),
                      _coin(),
                      const SizedBox(height: 14),
                      _heroAmount(),
                      const SizedBox(height: 20),
                      _streakRow(),
                      const SizedBox(height: 18),
                      _claimButton(),
                      const SizedBox(height: 10),
                      Text(
                        'Come back tomorrow for another 5-20.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyebrow() {
    return Text(
      'DAILY LOGIN REWARD',
      style: GoogleFonts.inter(
        color: const Color(0xFF9EF9FF),
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _coin() {
    return SizedBox(
      width: 148,
      height: 148,
      child: AnimatedBuilder(
        animation: Listenable.merge([_burst, _pulse]),
        child: _coinFace(),
        builder: (context, child) {
          final glow = Curves.easeInOut.transform(_pulse.value);
          return CustomPaint(
            painter: _RewardBurstPainter(
              progress: _burst.value,
              color: DailyLoginRewardDialog.gold,
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DailyLoginRewardDialog.gold.withValues(
                        alpha: 0.20 + glow * 0.22,
                      ),
                      blurRadius: 26 + glow * 20,
                      spreadRadius: 1 + glow * 4,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  // The artwork is already a struck coin with its own rim and fill, so it is
  // presented bare - only the glow it casts belongs to us.
  Widget _coinFace() => const HashCoinIcon(size: 96);

  /// The amount is the reason the card exists, so it carries the most weight.
  Widget _heroAmount() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _count,
          builder: (context, _) => ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFF3C9),
                DailyLoginRewardDialog.gold,
                Color(0xFFE0A21C),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              '+${_count.value}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'HASHCOINS',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }

  /// A visible run is the reason to come back tomorrow, so it earns a place
  /// above the fold rather than a line of body copy.
  ///
  /// The row is deliberately alive: a flame that flickers, segments that fill
  /// in sequence as the card lands, and a today-segment whose glow breathes -
  /// so a "Day 1" streak reads as something in motion, not a static bar.
  Widget _streakRow() {
    return Column(
      children: [
        _streakHeader(),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: Listenable.merge([_entry, _flicker]),
          builder: (context, _) {
            final flick = Curves.easeInOut.transform(_flicker.value);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(DailyLoginRewardDialog.streakTarget, (
                index,
              ) {
                final filled = index < _filledDays;
                final isToday = index == _filledDays - 1;

                // Each filled segment lands a beat after the previous one, so
                // the run reads as filling up rather than appearing at once.
                final start = (0.3 + index * 0.08).clamp(0.0, 0.85);
                final raw = ((_entry.value - start) / 0.22).clamp(0.0, 1.0);
                final appear = filled
                    ? Curves.easeOutBack.transform(raw)
                    : 1.0;

                final baseAlpha = filled ? (isToday ? 1.0 : 0.55) : 0.09;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Transform.scale(
                      scaleY: filled ? (0.4 + 0.6 * appear.clamp(0.0, 1.0)) : 1,
                      child: Opacity(
                        opacity: filled ? raw.clamp(0.2, 1.0) : 1,
                        child: Container(
                          height: isToday ? 8 : 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: filled
                                ? Color.lerp(
                                    DailyLoginRewardDialog.gold,
                                    DailyLoginRewardDialog.goldLight,
                                    isToday ? flick : 0,
                                  )!.withValues(alpha: baseAlpha)
                                : Colors.white.withValues(alpha: 0.09),
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: DailyLoginRewardDialog.gold
                                          .withValues(
                                            alpha: 0.35 + flick * 0.4,
                                          ),
                                      blurRadius: 8 + flick * 8,
                                      spreadRadius: flick * 1.5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  /// Flame + streak label. The flame flickers, lifts and glows on a loop so the
  /// header carries the "on a run" energy even at a one-day streak.
  Widget _streakHeader() {
    return AnimatedBuilder(
      animation: _flicker,
      builder: (context, _) {
        final f = Curves.easeInOut.transform(_flicker.value);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -f * 1.6),
              child: Transform.scale(
                scale: 0.92 + f * 0.16,
                child: Transform.rotate(
                  angle: (f - 0.5) * 0.10,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 22,
                    color: Color.lerp(
                      DailyLoginRewardDialog.gold,
                      DailyLoginRewardDialog.goldLight,
                      f,
                    ),
                    shadows: [
                      Shadow(
                        color: DailyLoginRewardDialog.gold.withValues(
                          alpha: 0.45 + f * 0.4,
                        ),
                        blurRadius: 12 + f * 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.streak > 1
                  ? 'Day ${widget.streak} streak'
                  : 'Streak started - keep it going',
              style: GoogleFonts.inter(
                color: DailyLoginRewardDialog.goldLight.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _claimButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD467), DailyLoginRewardDialog.gold],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: DailyLoginRewardDialog.gold.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _claim,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                'Claim',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Expanding ring plus radiating sparks, drawn behind the coin for the first
/// moment of the reward.
class _RewardBurstPainter extends CustomPainter {
  const _RewardBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const int _sparkCount = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = 1 - progress;

    canvas.drawCircle(
      center,
      base * (0.62 + eased * 0.36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 + (1 - eased) * 3
        ..color = color.withValues(alpha: fade * 0.55),
    );

    final sparkPaint = Paint()..color = color.withValues(alpha: fade * 0.95);
    for (var i = 0; i < _sparkCount; i++) {
      // Offset every other spark so the ring does not read as a clock face.
      final angle = (i / _sparkCount) * 2 * math.pi + (i.isEven ? 0 : 0.22);
      final reach = i.isEven ? 0.40 : 0.30;
      final distance = base * (0.64 + eased * reach);
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(offset, 0.8 + (1 - eased) * 2.8, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RewardBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
