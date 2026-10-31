import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:url_launcher/url_launcher.dart';

/// Slim home banner promoting Mumbai Surfer; tap opens its Play Store listing.
class HomeMumbaiSurferBanner extends StatelessWidget {
  const HomeMumbaiSurferBanner({super.key, this.openUrl});

  static const _asset = 'assets/mumbai_surfer_banner.webp';
  static const _aspect = 2000 / 667;

  static final playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.hashforgamers.mumbaisurfer',
  );

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
    await open(playStoreUri);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mumbai Surfer. Play now on Google Play.',
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
