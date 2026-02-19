import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/utils/app_logger.dart';

class UserController extends GetxController {
  // ───────── USER DATA ─────────
  var user = User(
    contact: Contact(
      electronicAddress: ElectronicAddress(emailId: '', mobileNo: ''),
      physicalAddress: PhysicalAddress(
        country: '',
        addressLine1: '',
        addressLine2: '',
        state: '',
      ),
    ),
    dob: '',
    gameUserName: '',
    gender: '',
    name: '',
    photoUrl: '',
  ).obs;

  // Backend user ID
  var id = ''.obs;

  var isLoading = false.obs;

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  Future<Map<String, dynamic>?> fetchUserData(String idValue) async {
    isLoading.value = true;
    final url = '${ApiEndpoints.checkUserExistsInAPI}$idValue';
    AppLogger.d('url to backend $url');
    try {
      final dio = locator<NetworkProvider>().noAuth();
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        AppLogger.d("✅ fetchUserData → backend id: ${data}");

        final fetchedUser = User.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        final photoFromPrefs = prefs.getString('photoUrl');
        final photoFromFirebase = firebase_auth.FirebaseAuth.instance.currentUser?.photoURL;
        fetchedUser.photoUrl = _firstNonEmpty([
          fetchedUser.photoUrl,
          photoFromPrefs,
          photoFromFirebase,
          user.value.photoUrl,
        ]);
        id.value = data['user']['id'].toString(); // ✅ backend userId

        setUserData(fetchedUser);

        AppLogger.d("✅ fetchUserData → backend id: ${id.value}");

        return data['user']; // 🔥 THIS WAS MISSING
      } else {
        AppLogger.d("❌ fetchUserData failed: ${response.data}");
        return null;
      }
    } catch (e) {
      AppLogger.d("❌ fetchUserData exception: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }


  /// ✅ Replace entire user object
  void setUserData(User fetchedUser) {
    final mergedPhoto = _firstNonEmpty([
      fetchedUser.photoUrl,
      user.value.photoUrl,
      firebase_auth.FirebaseAuth.instance.currentUser?.photoURL,
    ]);
    fetchedUser.photoUrl = mergedPhoto;
    user.value = fetchedUser;
  }

  /// ✅ Update Google-auth fields only
  void setGoogleUserData({required String name, required String photoUrl}) {
    user.update((val) {
      val?.name = name;
      val?.photoUrl = photoUrl;
    });
  }
// inside class UserController extends GetxController {
  final remoteRepo = locator<RemoteRepoInterface>();

  Future<bool> deleteUser() async {
    final res = await remoteRepo.deleteUser();
    return res['success'] == true;
  }

  /// 👤 Getter for current User ID
  String get userId => id.value;
}
