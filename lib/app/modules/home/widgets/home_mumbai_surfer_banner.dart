import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:url_launcher/url_launcher.dart';

/// Slim home banner promoting Mumbai Surfer; tap opens its store listing
/// (App Store on iOS, Play Store elsewhere).
class HomeMumbaiSurferBanner extends StatelessWidget {
  const HomeMumbaiSurferBanner({super.key, this.openUrl});

  static const _asset = 'assets/mumbai_surfer_banner.webp';
  static const _aspect = 2000 / 667;

  static final playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.hashforgamers.mumbaisurfer',
  );

  static final appStoreUri = Uri.parse(
    'https://apps.apple.com/us/app/mumbai-surfer-local-train-run/id6823804141',
  );

  static Uri get storeUri =>
      defaultTargetPlatform == TargetPlatform.iOS ? appStoreUri : playStoreUri;

  /// Overridable for tests; defaults to opening the link outside the app.
  final Future<bool> Function(Uri uri)? openUrl;

  Future<void> _open() async {
    Haptics.selection();
    if (locator.isRegistered<AnalyticsService>()) {
      unawaited(locator<AnalyticsService>().log('mumbai_surfer_banner_tapped'));
    }
    final open =
        openUrl ??
        (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    await open(storeUri);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mumbai Surfer. Play now.',
      excludeSemantics: true,
      child: HomeCard(
        padding: EdgeInsets.zero,
        onTap: () => unawaited(_open()),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: Image.asset(
            _asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(gradient: HomeTokens.brandGradient),
            ),
          ),
        ),
      ),
    );
  }
}
