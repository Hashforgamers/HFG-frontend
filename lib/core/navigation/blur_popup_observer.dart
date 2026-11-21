import 'dart:ui';

import 'package:flutter/material.dart';

/// Blurs the screen behind every dialog and modal bottom sheet, app-wide.
///
/// When a dialog/sheet route is pushed, a blur layer is added as the route's
/// own first overlay entry (just under its barrier). Because it belongs to the
/// route, the navigator keeps it directly beneath the popup whenever it
/// re-orders the overlay, and removes/disposes it with the route. A separate
/// overlay entry would be moved to the top by `Overlay.rearrange` and end up
/// blurring the popup itself.
class BlurPopupObserver extends NavigatorObserver {
  BlurPopupObserver({this.sigma = 7});

  final double sigma;
  final Expando<bool> _attached = Expando<bool>('blurAttached');

  static bool _shouldBlur(Route<dynamic> route) {
    if (route is! PopupRoute) return false;
    if (route is DialogRoute || route is ModalBottomSheetRoute) return true;
    // GetX (GetDialogRoute, GetModalBottomSheetRoute) and RawDialogRoute;
    // skips popup menus and dropdowns, which also extend PopupRoute.
    final name = route.runtimeType.toString();
    return name.contains('Dialog') || name.contains('BottomSheet');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_shouldBlur(route)) return;
    // Observers run while the navigator is locked and before the route's
    // entries reach the overlay, so attach after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach(route));
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _attach(Route<dynamic> route) {
    final popup = route as PopupRoute;
    final overlay = popup.navigator?.overlay;
    final animation = popup.animation;
    final entries = popup.overlayEntries;
    if (_attached[route] == true ||
        !popup.isActive ||
        overlay == null ||
        animation == null ||
        entries.isEmpty ||
        !entries.first.mounted) {
      return;
    }
    _attached[route] = true;

    final blur = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, _) {
            final t = Curves.easeOut.transform(animation.value.clamp(0, 1));
            if (t <= 0.01) return const SizedBox.expand();
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma * t, sigmaY: sigma * t),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
    final barrier = entries.first;
    entries.insert(0, blur);
    overlay.insert(blur, below: barrier);
  }
}
