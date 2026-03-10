import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentifierService {
  DeviceIdentifierService({required SharedPreferences preferences})
    : _preferences = preferences;

  static const MethodChannel _channel = MethodChannel(
    'device_identifier_channel',
  );

  static const String _advertisingIdKey = 'advertising_id';
  static const String _gaidKey = 'gaid';
  static const String _idfaKey = 'idfa';
  static const String _trackingStatusKey = 'ad_tracking_status';
  static const String _limitAdTrackingKey = 'limit_ad_tracking';
  static const String _allZeroId = '00000000-0000-0000-0000-000000000000';

  final SharedPreferences _preferences;
  Map<String, dynamic>? _cachedIdentifiers;

  Future<Map<String, dynamic>> getIdentifiers({bool refresh = false}) async {
    if (!refresh && _cachedIdentifiers != null) {
      return Map<String, dynamic>.from(_cachedIdentifiers!);
    }

    if (!refresh) {
      final stored = _readFromPreferences();
      if (_hasStoredIdentifiers(stored)) {
        _cachedIdentifiers = stored;
        return Map<String, dynamic>.from(stored);
      }
    }

    final identifiers = Platform.isAndroid
        ? await _getAndroidIdentifiers()
        : Platform.isIOS
        ? await _getIosIdentifiers()
        : _emptyIdentifiers();

    await _saveToPreferences(identifiers);
    _cachedIdentifiers = identifiers;
    return Map<String, dynamic>.from(identifiers);
  }

  Future<String> getPreferredAdvertisingId({bool refresh = false}) async {
    final identifiers = await getIdentifiers(refresh: refresh);
    return (identifiers['advertising_id'] ?? '').toString();
  }

  Future<Map<String, String>> buildRequestHeaders() async {
    final identifiers = await getIdentifiers();
    final headers = <String, String>{};

    void putIfNotEmpty(String key, dynamic value) {
      final normalized = (value ?? '').toString().trim();
      if (normalized.isNotEmpty) {
        headers[key] = normalized;
      }
    }

    putIfNotEmpty('X-Advertising-Id', identifiers['advertising_id']);
    putIfNotEmpty('X-GAID', identifiers['gaid']);
    putIfNotEmpty('X-IDFA', identifiers['idfa']);
    putIfNotEmpty('X-Ad-Tracking-Status', identifiers['ad_tracking_status']);
    if (identifiers['limit_ad_tracking'] != null) {
      headers['X-Limit-Ad-Tracking'] = identifiers['limit_ad_tracking']
          .toString();
    }

    return headers;
  }

  Map<String, dynamic> _readFromPreferences() {
    return {
      'advertising_id': _preferences.getString(_advertisingIdKey) ?? '',
      'gaid': _preferences.getString(_gaidKey) ?? '',
      'idfa': _preferences.getString(_idfaKey) ?? '',
      'ad_tracking_status': _preferences.getString(_trackingStatusKey) ?? '',
      'limit_ad_tracking': _preferences.getBool(_limitAdTrackingKey) ?? false,
    };
  }

  Future<void> _saveToPreferences(Map<String, dynamic> identifiers) async {
    await _preferences.setString(
      _advertisingIdKey,
      (identifiers['advertising_id'] ?? '').toString(),
    );
    await _preferences.setString(
      _gaidKey,
      (identifiers['gaid'] ?? '').toString(),
    );
    await _preferences.setString(
      _idfaKey,
      (identifiers['idfa'] ?? '').toString(),
    );
    await _preferences.setString(
      _trackingStatusKey,
      (identifiers['ad_tracking_status'] ?? '').toString(),
    );
    await _preferences.setBool(
      _limitAdTrackingKey,
      identifiers['limit_ad_tracking'] == true,
    );
  }

  bool _hasStoredIdentifiers(Map<String, dynamic> identifiers) {
    return (identifiers['advertising_id'] ?? '').toString().trim().isNotEmpty ||
        (identifiers['gaid'] ?? '').toString().trim().isNotEmpty ||
        (identifiers['idfa'] ?? '').toString().trim().isNotEmpty ||
        (identifiers['ad_tracking_status'] ?? '').toString().trim().isNotEmpty;
  }

  Future<Map<String, dynamic>> _getAndroidIdentifiers() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getAdvertisingInfo',
      );
      final gaid = (raw?['gaid'] ?? '').toString().trim();
      final limited = raw?['isLimitAdTrackingEnabled'] == true;
      return {
        'advertising_id': gaid,
        'gaid': gaid,
        'idfa': '',
        'ad_tracking_status': limited ? 'limited' : 'available',
        'limit_ad_tracking': limited,
      };
    } catch (_) {
      return _emptyIdentifiers();
    }
  }

  Future<Map<String, dynamic>> _getIosIdentifiers() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      final rawIdfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      final idfa = _normalizeIdentifier(rawIdfa);
      return {
        'advertising_id': idfa,
        'gaid': '',
        'idfa': idfa,
        'ad_tracking_status': status.name,
        'limit_ad_tracking': status != TrackingStatus.authorized,
      };
    } catch (_) {
      return _emptyIdentifiers();
    }
  }

  Map<String, dynamic> _emptyIdentifiers() {
    return {
      'advertising_id': '',
      'gaid': '',
      'idfa': '',
      'ad_tracking_status': '',
      'limit_ad_tracking': false,
    };
  }

  String _normalizeIdentifier(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == _allZeroId) {
      return '';
    }
    return normalized;
  }
}
