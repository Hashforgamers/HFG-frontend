import 'package:flutter/material.dart';

enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final Map<String, String> baseUrls;
  final String appId;
  final String bundleId;
  final String appIcon;
  final Color primaryColor;
  final Color accentColor;

  static FlavorConfig? _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required String appName,
    required Map<String, String> baseUrls,
    required String appId,
    required String bundleId,
    required String appIcon,
    required Color primaryColor,
    required Color accentColor,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      appName: appName,
      baseUrls: baseUrls,
      appId: appId,
      bundleId: bundleId,
      appIcon: appIcon,
      primaryColor: primaryColor,
      accentColor: accentColor,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required this.appName,
    required this.baseUrls,
    required this.appId,
    required this.bundleId,
    required this.appIcon,
    required this.primaryColor,
    required this.accentColor,
  });

  static FlavorConfig get instance {
    return _instance ?? (throw Exception('FlavorConfig not initialized'));
  }

  static bool isProduction() => _instance?.flavor == Flavor.prod;
  static bool isDevelopment() => _instance?.flavor == Flavor.dev;

  static String getBaseUrl(String key) {
    return instance.baseUrls[key] ?? '';
  }
} 