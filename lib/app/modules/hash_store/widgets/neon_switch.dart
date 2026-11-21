import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// The Hash Shop "neon unfold" effects: a green-to-purple shockwave rolling
/// out from [origin] and a neon streak racing along the top edge from
/// [streakFrom] to [streakTo]. [t] runs 0..1; nothing paints at either end.
class NeonFxPainter extends CustomPainter {
  final double t;
  final Offset origin;
  final double streakFrom;
  final double streakTo;

  /// Final ring radius as a fraction of the width.
  final double reach;

  const NeonFxPainter({
    required this.t,
    required this.origin,
    required this.streakFrom,
    required this.streakTo,
    this.reach = 1.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    final wave = ((t - 0.02) / 0.7).clamp(0.0, 1.0);
    if (wave > 0 && wave < 1) {
      final r = size.width * reach * Curves.easeOutCubic.transform(wave);
      final fade = 1 - wave;
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 10 * fade
          ..shader = RadialGradient(
            colors: [
              StoreColors.greenSoft.withValues(alpha: 0.0),
              StoreColors.greenSoft.withValues(alpha: 0.55 * fade),
              StoreColors.purpleSoft.withValues(alpha: 0.45 * fade),
            ],
            stops: const [0.6, 0.9, 1],
          ).createShader(Rect.fromCircle(center: origin, radius: r + 12)),
      );
    }

    final run = ((t - 0.18) / 0.62).clamp(0.0, 1.0);
    if (run > 0 && run < 1) {
      final x = lerpDouble(
        streakFrom,
        streakTo,
        Curves.easeInOutCubic.transform(run),
      )!;
      const len = 120.0;
      final glow = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            StoreColors.greenSoft,
            Colors.white,
            StoreColors.purpleSoft.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 0.5, 1],
        ).createShader(Rect.fromLTWH(x - len / 2, 0, len, 2));
      canvas.drawLine(Offset(x - len / 2, 1), Offset(x + len / 2, 1), glow);
      // Soft halo under the streak.
      canvas.drawCircle(
        Offset(x, 1),
        26,
        Paint()
          ..shader = RadialGradient(
            colors: [
              StoreColors.greenSoft.withValues(alpha: 0.35),
              StoreColors.greenSoft.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, 1), radius: 26)),
      );
    }
  }

  @override
  bool shouldRepaint(NeonFxPainter old) =>
      old.t != t ||
      old.origin != origin ||
      old.streakFrom != streakFrom ||
      old.streakTo != streakTo;
}

/// Replays the Hash Shop dock's "neon unfold" over a row of [count]
/// equal-width tabs whenever the selection changes, on the dock's own spring:
/// the shockwave rolls out from the tapped tab, the neon streak races along
/// the top edge from that side to the far one, and every [NeonFlip] tab
/// below swings down into place, nearest the tapped tab first.
///
/// Give [index], or a [controller] to follow a [TabBar]. Turn [wave] off
/// where tabs are not equal width (scrollable bars, chip rows); the tabs
/// still flip in.
class NeonSwitchFx extends StatefulWidget {
  final int index;
  final int count;
  final TabController? controller;
  final bool wave;

  /// Spring response in seconds; the dock's is 0.55. Higher is slower.
  final double response;
  final Widget child;

  const NeonSwitchFx({
    super.key,
    required this.index,
    required this.count,
    this.wave = true,
    this.response = 0.55,
    required this.child,
  }) : controller = null;

  NeonSwitchFx.tabs({
    super.key,
    required TabController this.controller,
    this.wave = true,
    this.response = 0.55,
    required this.child,
  }) : index = controller.index,
       count = controller.length;

  @override
  State<NeonSwitchFx> createState() => _NeonSwitchFxState();
}

class _NeonSwitchFxState extends State<NeonSwitchFx>
    with SingleTickerProviderStateMixin {
  // Settled at 1; a switch replays 0 -> 1 like the dock opening.
  late final _t = AnimationController.unbounded(vsync: this, value: 1);
  late int _index = widget.index;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTab);
  }

  @override
  void didUpdateWidget(NeonSwitchFx old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onTab);
      widget.controller?.addListener(_onTab);
    }
    if (widget.controller == null) _switchTo(widget.index);
  }

  void _onTab() => _switchTo(widget.controller!.index);

  void _switchTo(int index) {
    if (index == _index) return;
    _index = index;
    if (storeReduceMotion(context)) return;
    // The dock opening's spring (HashShopDock.didUpdateWidget), at [response].
    _t.animateWith(
      SpringSimulation(
        storeSpring(damping: 0.78, response: widget.response),
        0,
        1,
        0,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTab);
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final count = widget.count.clamp(1, 99);
      final slot = c.maxWidth / count;
      final x = slot * (_index + 0.5);
      final fromRight = x > c.maxWidth / 2;
      return AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value.clamp(0.0, 1.0);
          return _NeonScope(
            t: t,
            origin: _index,
            count: count,
            child: widget.wave && c.maxWidth.isFinite
                ? CustomPaint(
                    foregroundPainter: NeonFxPainter(
                      t: t,
                      origin: Offset(
                        x,
                        c.maxHeight.isFinite ? c.maxHeight / 2 : 24,
                      ),
                      streakFrom: fromRight ? c.maxWidth : 0,
                      streakTo: fromRight ? 0 : c.maxWidth,
                    ),
                    child: child,
                  )
                : child!,
          );
        },
        child: widget.child,
      );
    },
  );
}

class _NeonScope extends InheritedWidget {
  final double t;
  final int origin;
  final int count;
  const _NeonScope({
    required this.t,
    required this.origin,
    required this.count,
    required super.child,
  });

  @override
  bool updateShouldNotify(_NeonScope old) =>
      old.t != t || old.origin != origin || old.count != count;
}

/// The dock's split-flap tab entrance: tab [slot] swings down from above in
/// 3D, its turn staggered by distance from the tapped tab, exactly as the
/// dock's tabs land right to left from the pill. Lives under [NeonSwitchFx].
class NeonFlip extends StatelessWidget {
  final int slot;
  final Widget child;
  const NeonFlip({super.key, required this.slot, required this.child});

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_NeonScope>();
    if (scope == null || scope.t >= 1) return child;
    // The dock staggers 4 tabs 0.11 apart from 0.32; more tabs share the
    // same window so the last still lands by t = 1.
    final step = scope.count > 1 ? math.min(0.11, 0.33 / (scope.count - 1)) : 0;
    final rank = (slot - scope.origin).abs();
    final p = ((scope.t - (0.32 + step * rank)) / 0.34).clamp(0.0, 1.0);
    // Landed: a spring can settle a hair under t = 1, and an at-rest
    // perspective layer drew hairlines along the icon edges.
    if (p >= 1) return child;
    final e = Curves.easeOutBack.transform(p);
    return IgnorePointer(
      ignoring: p < 0.6,
      child: Opacity(
        opacity: p,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: storePerspective(rotateX: (1 - e) * -1.45)
            ..translateByDouble(0, 10 * (1 - p), 0, 1),
          child: child,
        ),
      ),
    );
  }
}

/// A [TabBar] with [NeonSwitchFx] played over it; a drop-in for an
/// [AppBar.bottom] or any slot. Build its tabs with [neonTabs]. Scrollable
/// bars skip the wave, since their tabs differ in width.
class NeonTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabBar tabBar;
  const NeonTabBar(this.tabBar, {super.key});

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => NeonSwitchFx.tabs(
    controller: tabBar.controller ?? DefaultTabController.of(context),
    wave: !tabBar.isScrollable,
    child: tabBar,
  );
}

/// Wraps each tab in a [NeonFlip] for a [NeonTabBar].
List<Widget> neonTabs(List<Widget> tabs) => [
  for (final (i, tab) in tabs.indexed) NeonFlip(slot: i, child: tab),
];
