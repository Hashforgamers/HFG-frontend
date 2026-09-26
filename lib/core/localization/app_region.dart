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

/// Currency formatting driven by the **money's own currency**, not the device
/// locale.
///
/// Important: a symbol swap alone is misleading — ₹30 is not $30. The symbol
/// therefore follows the currency the amount is actually denominated in. Today
/// the app settles entirely in INR (backend + Razorpay), so [settlementCurrency]
/// is `INR` and amounts render as ₹ everywhere, regardless of the phone's
/// locale. When the backend can hold/charge USD (the Stripe workstream), pass
/// `currency: 'USD'` for those amounts (or flip [settlementCurrency]) and they
/// render as $ — the value itself must already be in that currency; this class
/// never does FX conversion.
class Money {
  Money._();

  /// The currency the app actually holds/charges in today.
  static const String settlementCurrency = 'INR';

  static String _symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'INR':
      default:
        return '₹';
    }
  }

  static String _localeFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'en_US';
      case 'INR':
      default:
        return 'en_IN';
    }
  }

  /// The symbol of the app's settlement currency (₹ today).
  static String get symbol => _symbolFor(settlementCurrency);

  /// Format [amount], which is assumed to already be in [currency] (defaults to
  /// the settlement currency). Whole numbers show no decimals by default.
  static String format(num amount, {int? decimals, String? currency}) {
    final code = (currency ?? settlementCurrency);
    final digits = decimals ?? (amount % 1 == 0 ? 0 : 2);
    return NumberFormat.currency(
      locale: _localeFor(code),
      symbol: _symbolFor(code),
      decimalDigits: digits,
    ).format(amount);
  }
}
