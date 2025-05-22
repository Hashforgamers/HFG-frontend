import 'dart:convert';

import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteRepo implements RemoteRepoInterface {
  final NetworkProvider networkProvider;

  RemoteRepo({required this.networkProvider});

  @override
  Future<Map<String, dynamic>?> checkUserExistsInAPI(String fid) async {
    final dio = networkProvider.noAuth();

    try {
      final response = await dio.get(
        ApiEndpoints.checkUserExistsInAPI + fid,
      );

      if (response.statusCode == 200) {
        // Dio already decodes the response data, so we don't need jsonDecode
        final Map<String, dynamic> responseBody = response.data;
        final Map<String, dynamic>? userData = responseBody['user'];

        if (userData != null) {
          // Save user data to preferences when found
          await saveUserToPreferences(userData);
          return userData;
        }
      }
      return null;
    } catch (e) {
      print('Error checking user existence: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserToPreferences(Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    print('User data saved to preferences.');
  }

  @override
  Future<Map<String, dynamic>?> getUserFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> clearUserFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    print('User data cleared from preferences.');
  }
}
