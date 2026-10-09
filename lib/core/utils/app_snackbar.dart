import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Crash-safe replacement for `Get.snackbar`.
///
/// GetX 4.7 dereferences `Get.overlayContext!` when it builds a snackbar. If no
/// navigator overlay is mounted yet (splash, auth redirects, a route mid-
/// transition) that throws, leaving the controller half-built so the later
/// close crashes too (`LateInitializationError: _controller`). Here we wait one
/// frame for an overlay and drop the message if there still isn't one.
abstract final class AppSnackbar {
  static bool get _hasOverlay {
    final ctx = Get.overlayContext;
    return ctx != null &&
        ctx.mounted &&
        Overlay.maybeOf(ctx, rootOverlay: true) != null;
  }

  static void show(
    String title,
    String message, {
    SnackPosition? snackPosition,
    Color? colorText,
    Color? backgroundColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Duration duration = const Duration(seconds: 3),
    Widget? icon,
    bool? isDismissible,
    DismissDirection? dismissDirection,
  }) {
    void present() {
      if (!_hasOverlay) {
        debugPrint('[AppSnackbar] no overlay, dropped: $title');
        return;
      }
      try {
        Get.snackbar(
          title,
          message,
          snackPosition: snackPosition,
          colorText: colorText,
          backgroundColor: backgroundColor,
          margin: margin,
          padding: padding,
          borderRadius: borderRadius,
          duration: duration,
          icon: icon,
          isDismissible: isDismissible,
          dismissDirection: dismissDirection,
        );
      } catch (e) {
        debugPrint('[AppSnackbar] failed: $e');
      }
    }

    if (_hasOverlay) {
      present();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => present());
    }
  }
}
