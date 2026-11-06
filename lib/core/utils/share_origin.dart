import 'package:flutter/widgets.dart';

/// The anchor rectangle the iOS share sheet needs on iPad.
///
/// On iPad the share sheet is a popover and `share_plus` throws
/// ("sharePositionOrigin: argument must be set") when it has no non-empty
/// rectangle to point at. Pass the [context] of the button that was tapped to
/// anchor the popover to it; without one (or if it isn't laid out) the sheet
/// is anchored to the middle of the screen. iPhone and Android ignore it.
Rect shareOriginRect([BuildContext? context]) {
  final box = context?.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.isEmpty) return rect;
  }
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
  final view = views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  if (size.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
  return Rect.fromCenter(center: size.center(Offset.zero), width: 2, height: 2);
}
