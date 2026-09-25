import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Regions the app can localize for. Add more as the app expands.
enum AppCountry { india, unitedStates }

/// Central, locale-driven region config so the app can present correctly in
/// India (₹, +91) or the US ($, +1) instead of hard-coding India everywhere.
///
/// Detection order: an explicit [override] (e.g. from the signed-in user's
/// profile) wins; otherwise the device locale's country code decides; India is
/// the safe default for existing users.
class AppRegion {
  AppRegion._();

  static AppCountry? _override;

  /// Force a region (e.g. from the user's account country). Pass null to fall
  /// back to device-locale detection.
  static void setOverride(AppCountry? country) => _override = country;

  static AppCountry get current => _override ?? _fromDeviceLocale();

  static AppCountry _fromDeviceLocale() {
    final code = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.toUpperCase();
    return code == 'US' ? AppCountry.unitedStates : AppCountry.india;
  }

  static bool get isUS => current == AppCountry.unitedStates;

  // ---- Currency ----
  static String get currencyCode => isUS ? 'USD' : 'INR';
  static String get currencySymbol => isUS ? r'$' : '₹';

  /// Locale tag used for number/date formatting (grouping, decimals).
  static String get localeTag => isUS ? 'en_US' : 'en_IN';

  // ---- Telephony ----
  static String get dialCode => isUS ? '+1' : '+91';
  static String get phoneIso => isUS ? 'US' : 'IN';

  // ---- Geo defaults (used as a map fallback before the user's real GPS
  // location is known). US -> a central US point; IN -> Bengaluru. ----
  static LatLng get defaultCenter => isUS
      ? const LatLng(39.8283, -98.5795) // geographic center of the US
      : const LatLng(12.9716, 77.5946); // Bengaluru

  /// Keyword-search radius default for nearby cafes, in metres.
  static int get nearbyRadiusMeters => isUS ? 40000 : 10000;
}

/// Locale-aware currency formatting. Replaces scattered `'₹$amount'` strings.
///
/// Note: this formats the *display* only — it does not convert values between
/// currencies. Actual pricing/FX is a backend/business concern.
class Money {
  Money._();

  /// Format [amount] with the current region's symbol and grouping.
  /// By default whole numbers show no decimals and fractional values show two.
  static String format(num amount, {int? decimals}) {
    final digits = decimals ?? (amount % 1 == 0 ? 0 : 2);
    final formatter = NumberFormat.currency(
      locale: AppRegion.localeTag,
      symbol: AppRegion.currencySymbol,
      decimalDigits: digits,
    );
    return formatter.format(amount);
  }

  /// Just the current region's currency symbol (₹ / $).
  static String get symbol => AppRegion.currencySymbol;
}
