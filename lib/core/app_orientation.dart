import 'package:flutter/services.dart';

/// The app is portrait-only. Games that need landscape switch to it while
/// they're open and call [portrait] again on the way out.
class AppOrientation {
  AppOrientation._();

  static Future<void> portrait() => SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp],
      );

  static Future<void> landscape() => SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
}
