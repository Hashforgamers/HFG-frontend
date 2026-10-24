import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/core/utils/haptics.dart';

/// The Hash Shop dock. Closed, it is the "HASH SHOP" pill on the right of
/// the main tab bar; open, it is the shop's own nav bar covering that tab bar.
///
/// Opening is a "neon unfold": the pill stretches into the bar on a spring,
/// a green-to-purple shockwave rolls out from the pill, a neon streak runs
/// along the top edge, and the tabs flip down into place right to left. It
/// is one continuous, interruptible value, so closing plays the same path
/// back and a tap mid-flight reverses from wherever it is.
class HashShopDock extends StatefulWidget {
  final bool open;

  /// [ShopController.shopMenuIndex]: 0 store, 2 cart, 3 orders.
  final int activeIndex;
  final HashStoreCartCubit cart;
  final VoidCallback onOpen;
  final ValueChanged<int> onSelect;
  final VoidCallback onExit;

  /// Height of the bar above the home indicator; matches the main tab bar.
  static const barHeight = kBottomNavigationBarHeight;

  const HashShopDock({
    super.key,
    required this.open,
    required this.activeIndex,
    required this.cart,
    required this.onOpen,
    required this.onSelect,
    required this.onExit,
  });

  @override
  State<HashShopDock> createState() => _HashShopDockState();
}

class _HashShopDockState extends State<HashShopDock>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController.unbounded(
    vsync: this,
    value: widget.open ? 1 : 0,
  );

  static const _pillWidth = 84.0;
  static const _pillHeight = 46.0;

  static const _tabs = [
    (index: -1, icon: Icons.arrow_back_ios_new_rounded, label: 'Hash App'),
    (index: 0, icon: Icons.storefront_rounded, label: 'Shop'),
    (index: 2, icon: Icons.shopping_bag_rounded, label: 'Cart'),
    (index: 3, icon: Icons.receipt_long_rounded, label: 'Orders'),
  ];

  @override
  void didUpdateWidget(HashShopDock old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    final target = widget.open ? 1.0 : 0.0;
    if (storeReduceMotion(context)) {
      _t.value = target;
      return;
    }
    // Starts from the live value and velocity, so it can be reversed mid-way.
    _t.animateWith(
      SpringSimulation(
        storeSpring(damping: widget.open ? 0.78 : 1, response: 0.55),
        _t.value,
        target,
        _t.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// 0..1 progress of [t] through the window [from, from + span].
  static double _phase(double t, double from, double span) =>
      ((t - from) / span).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final solid = storeHighContrast(context);
    return LayoutBuilder(
      builder: (context, c) {
        final fullW = c.maxWidth;
        final fullH = HashShopDock.barHeight + bottomInset;
        return AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final raw = _t.value;
            final t = raw.clamp(0.0, 1.0);
            // Width may overshoot a touch on open, like liquid settling.
            final width = lerpDouble(
              _pillWidth,
              fullW,
              raw.clamp(0.0, 1.04),
            )!.clamp(_pillWidth, fullW);
            final shape = Curves.easeOutCubic.transform(t);
            final height = lerpDouble(_pillHeight, fullH, shape)!;
            final lift = lerpDouble(bottomInset + 5, 0, shape)!;
            final radius = BorderRadius.only(
              topLeft: const Radius.circular(24),
              bottomLeft: Radius.circular(lerpDouble(24, 0, shape)!),
              topRight: Radius.circular(lerpDouble(0, 24, shape)!),
            );
            final open = t > 0.5;

            return Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: lift,
                  width: width,
                  height: height,
                  child: Semantics(
                    container: true,
                    label: open ? 'Hash Shop navigation' : null,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: lerpDouble(6, 20, t)!,
                          sigmaY: lerpDouble(6, 20, t)!,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            color: solid ? Colors.black : null,
                            gradient: solid
                                ? null
                                : LinearGradient.lerp(
                                    LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.08),
                                        StoreColors.purple.withValues(
                                          alpha: 0.28,
                                        ),
                                        Colors.black.withValues(alpha: 0.48),
                                      ],
                                    ),
                                    LinearGradient(
                                      colors: [
                                        StoreColors.green.withValues(
                                          alpha: 0.14,
                                        ),
                                        Colors.black.withValues(alpha: 0.82),
                                        StoreColors.purple.withValues(
                                          alpha: 0.42,
                                        ),
                                      ],
                                    ),
                                    t,
                                  ),
                            border: Border.all(
                              color: solid
                                  ? Colors.white54
                                  : Color.lerp(
                                      StoreColors.purple.withValues(
                                        alpha: 0.45,
                                      ),
                                      Colors.white.withValues(alpha: 0.10),
                                      t,
                                    )!,
                            ),
                          ),
                          child: CustomPaint(
                            foregroundPainter: _UnfoldFx(
                              t: t,
                              opening: widget.open,
                              originFromRight: _pillWidth / 2,
                              // Stays where the pill was while the dock grows.
                              originFromBottom:
                                  bottomInset + 5 + _pillHeight / 2 - lift,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (t < 0.4) _pillLabel(t),
                                if (t > 0.3)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: bottomInset * shape,
                                    ),
                                    child: _tabsRow(fullW, t),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _pillLabel(double t) {
    final p = _phase(t, 0, 0.3);
    return IgnorePointer(
      ignoring: t > 0.05,
      child: Semantics(
        button: true,
        label: 'Open Hash Shop',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpen,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: _pillWidth,
              child: Opacity(
                opacity: 1 - p,
                child: Transform.translate(
                  offset: Offset(18 * p, 0),
                  child: Transform.scale(
                    scale: 1 - 0.3 * p,
                    child: Center(
                      child: Text(
                        'HASH\nSHOP',
                        style: storeDisplay(12).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabsRow(double fullW, double t) {
    final slot = fullW / _tabs.length;
    final activeSlot = _tabs.indexWhere((x) => x.index == widget.activeIndex);
    final indicator = _phase(t, 0.78, 0.22);
    return OverflowBox(
      alignment: Alignment.bottomRight,
      minWidth: fullW,
      maxWidth: fullW,
      maxHeight: HashShopDock.barHeight,
      minHeight: HashShopDock.barHeight,
      child: Stack(
        children: [
          // Sliding active-tab pill; grows in last, once the tabs have landed.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: activeSlot * slot + 8,
            width: slot - 16,
            top: 5,
            bottom: 5,
            child: Opacity(
              opacity: indicator,
              child: Transform.scale(
                scaleX: 0.4 + 0.6 * indicator,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: StoreColors.green.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: StoreColors.green.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, tab) in _tabs.indexed)
                _flipIn(
                  // Right to left: Orders lands first, Hash App last.
                  _phase(t, 0.32 + 0.11 * (_tabs.length - 1 - i), 0.34),
                  _NavItem(
                    width: slot,
                    icon: tab.icon,
                    iconSize: tab.index == -1 ? 17 : 22,
                    label: tab.label,
                    selected: tab.index == widget.activeIndex,
                    badge: tab.index == 2 ? _cartBadge() : null,
                    onTap: () {
                      Haptics.selection();
                      if (tab.index == -1) {
                        widget.onExit();
                      } else if (tab.index != widget.activeIndex) {
                        widget.onSelect(tab.index);
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Split-flap entrance: the tab swings down from above in 3D.
  Widget _flipIn(double p, Widget child) {
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

  Widget _cartBadge() => BlocBuilder<HashStoreCartCubit, HashStoreCartState>(
    bloc: widget.cart,
    buildWhen: (a, b) => a.itemCount != b.itemCount,
    builder: (_, s) => s.itemCount == 0
        ? const SizedBox.shrink()
        : StorePop(trigger: s.itemCount, child: _Badge('${s.itemCount}')),
  );
}

/// Shockwave ring and top-edge neon streak for the unfold.
class _UnfoldFx extends CustomPainter {
  final double t;
  final bool opening;
  final double originFromRight;
  final double originFromBottom;
  const _UnfoldFx({
    required this.t,
    required this.opening,
    required this.originFromRight,
    required this.originFromBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(
      size.width - originFromRight,
      size.height - originFromBottom.clamp(0, size.height),
    );

    // Shockwave: a ring rolling out from the pill, fading as it grows.
    final wave = ((t - 0.02) / 0.7).clamp(0.0, 1.0);
    if (wave > 0 && wave < 1) {
      final r = size.width * 1.15 * Curves.easeOutCubic.transform(wave);
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

    // Neon streak racing along the top edge, right to left.
    final run = ((t - 0.18) / 0.62).clamp(0.0, 1.0);
    if (run > 0 && run < 1) {
      final x = size.width * (1 - Curves.easeInOutCubic.transform(run));
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
  bool shouldRepaint(_UnfoldFx old) => old.t != t;
}

class _NavItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final double iconSize;
  final String label;
  final bool selected;
  final Widget? badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.width,
    required this.icon,
    this.iconSize = 22,
    required this.label,
    required this.selected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? StoreColors.greenSoft : Colors.white70;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(icon, size: iconSize, color: color),
                    ),
                    if (badge != null)
                      Positioned(top: -6, right: -4, child: badge!),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: storeBody(
                  size: 10.5,
                  color: color,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18),
    height: 18,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: StoreColors.green,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.black, width: 1.5),
    ),
    child: Text(
      text,
      style: storeBody(size: 9.5, color: Colors.black, weight: FontWeight.w800),
    ),
  );
}
