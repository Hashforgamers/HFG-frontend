import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthDataRepository {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;

  AuthDataRepository({
    FlutterSecureStorage? storage,
    SharedPreferences? prefs,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _prefs = prefs ?? locator<SharedPreferences>();

  // Save tokens after successful login
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      debugPrint('Attempting to save tokens to secure storage');

      // Try secure storage first
      try {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
        debugPrint('Tokens saved to secure storage successfully');
        return;
      } catch (secureStorageError) {
        debugPrint(
            'Secure storage failed, falling back to SharedPreferences: $secureStorageError');
      }

      // Fallback to SharedPreferences if secure storage fails
      await _prefs.setString(_accessTokenKey, accessToken);
      await _prefs.setString(_refreshTokenKey, refreshToken);
      debugPrint('Tokens saved to SharedPreferences successfully');
    } catch (e) {
      debugPrint('Error saving tokens: $e');
      rethrow;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      // Try secure storage first
      String? token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        debugPrint('Retrieved access token from secure storage');
        return token;
      }

      // Fallback to SharedPreferences
      token = _prefs.getString(_accessTokenKey);
      debugPrint(
          'Retrieved access token from SharedPreferences: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      // Try secure storage first
      String? token = await _storage.read(key: _refreshTokenKey);
      if (token != null) {
        debugPrint('Retrieved refresh token from secure storage');
        return token;
      }

      // Fallback to SharedPreferences
      token = _prefs.getString(_refreshTokenKey);
      debugPrint(
          'Retrieved refresh token from SharedPreferences: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Clear tokens on logout
  Future<void> clearTokens() async {
    try {
      debugPrint('Attempting to clear tokens');

      // Clear from both storage methods
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_refreshTokenKey);

      debugPrint('Tokens cleared successfully');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
      rethrow;
    }
  }

  // Update access token (useful during token refresh)
  Future<void> updateAccessToken(String newAccessToken) async {
    try {
      debugPrint('Attempting to update access token');

      // Try secure storage first
      try {
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        debugPrint('Access token updated in secure storage');
        return;
      } catch (secureStorageError) {
        debugPrint(
            'Secure storage failed, falling back to SharedPreferences: $secureStorageError');
      }

      // Fallback to SharedPreferences
      await _prefs.setString(_accessTokenKey, newAccessToken);
      debugPrint('Access token updated in SharedPreferences');
    } catch (e) {
      debugPrint('Error updating access token: $e');
      rethrow;
    }
  }
}
