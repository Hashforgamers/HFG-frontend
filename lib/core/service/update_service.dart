import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static const _kMinAndroid   = 'min_supported_version_android';
  static const _kLatestAndroid= 'latest_version_android';
  static const _kStoreAndroid = 'store_url_android';

  static const _kMinIOS       = 'min_supported_version_ios';
  static const _kLatestIOS    = 'latest_version_ios';
  static const _kStoreIOS     = 'store_url_ios';

  /// Returns true if a **hard block** was shown (app should stop normal flow).
  Future<bool> enforce(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      final rc = FirebaseRemoteConfig.instance;

      // ↓↓↓ Debug-friendly fetch (so it doesn’t cache for an hour)
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 1), // was minutes:5
      ));
      await rc.fetchAndActivate();

      final isAndroid = Platform.isAndroid;
      final min     = rc.getString(isAndroid ? _kMinAndroid : _kMinIOS);
      final latest  = rc.getString(isAndroid ? _kLatestAndroid : _kLatestIOS);
      final store   = rc.getString(isAndroid ? _kStoreAndroid : _kStoreIOS);

      // ↓↓↓ Loud diagnostics so you can see why it didn’t trigger
      debugPrint('🔎 RC fetched → current=$current  min=$min  latest=$latest  store=$store');

      final belowMin    = _cmpSemver(current, min)    < 0;
      final belowLatest = _cmpSemver(current, latest) < 0;

      if (belowMin) {
        if (isAndroid) {
          try {
            final r = await InAppUpdate.checkForUpdate();
            if (r.updateAvailability == UpdateAvailability.updateAvailable) {
              await InAppUpdate.performImmediateUpdate();
              return true;
            }
          } catch (_) {/* fall back to dialog */}
        }
        await _showForceDialog(context, store, latest, current);
        return true;
      }

      if (belowLatest) {
        _showSoftSnack(context, store, latest, current);
      }
    } catch (e) {
      debugPrint('⚠️ UpdateService error: $e'); // don’t block app if RC fails
    }
    return false;
  }


  // ────────────────────── UI helpers ─────────────────────────

  Future<void> _showForceDialog(
      BuildContext context, String storeUrl, String latest, String current) async {
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          "Update Required",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "You’re on version $current.\n\nTo continue using the app, please update to version $latest.",
            style: TextStyle(fontSize: 15, height: 1.3),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async => _openStore(storeUrl),
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }


  void _showSoftSnack(
      BuildContext context, String storeUrl, String latest, String current) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text('New version $latest is available (you are on $current).'),
        leading: const Icon(Icons.system_update),
        backgroundColor: Colors.amber.shade700,
        actions: [
          TextButton(
            onPressed: () async => _openStore(storeUrl),
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Simple semver compare: -1 if a<b, 0 if =, 1 if a>b
  int _cmpSemver(String a, String b) {
    List<int> p(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList(growable: false);
    final av = p(a), bv = p(b);
    for (var i = 0; i < 3; i++) {
      if (av[i] != bv[i]) return av[i].compareTo(bv[i]);
    }
    return 0;
  }
}
