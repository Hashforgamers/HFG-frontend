import 'dart:convert';
import 'package:get/get.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import '../models/user_model.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/utils/app_logger.dart';

class UserController extends GetxController {
  static User _emptyUser() {
    return User(
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
    );
  }

  // ───────── USER DATA ─────────
  var user = _emptyUser().obs;

  // Backend user ID
  var id = ''.obs;

  var isLoading = false.obs;

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

        applyBackendUserData(data['user']);

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
    user.value = fetchedUser;
  }

  /// ✅ Replace user + backend id from API payload
  void applyBackendUserData(Map<String, dynamic> userData) {
    setUserData(User.fromJson(userData));
    id.value = (userData['id'] ?? userData['user_id'] ?? '').toString().trim();
  }

  void clearSession() {
    user.value = _emptyUser();
    id.value = '';
    isLoading.value = false;
  }

  /// ✅ Update Google-auth fields only
  void setGoogleUserData({
    required String name,
    required String photoUrl,
    String? email,
    String? gameUserName,
    String? gender,
    String? dob,
    String? addressLine1,
    String? addressLine2,
    String? state,
    String? country,
  }) {
    user.update((val) {
      if (val == null) return;
      val.name = name;
      val.photoUrl = photoUrl;
      if ((email ?? '').trim().isNotEmpty) {
        val.contact ??= Contact(
          electronicAddress: ElectronicAddress(emailId: '', mobileNo: ''),
          physicalAddress: PhysicalAddress(
            country: '',
            addressLine1: '',
            addressLine2: '',
            state: '',
          ),
        );
        val.contact?.electronicAddress ??= ElectronicAddress(
          emailId: '',
          mobileNo: '',
        );
        val.contact?.electronicAddress?.emailId = email!.trim();
      }
      if ((gameUserName ?? '').trim().isNotEmpty) {
        val.gameUserName = gameUserName!.trim();
      }
      if ((gender ?? '').trim().isNotEmpty) {
        val.gender = gender!.trim();
      }
      if ((dob ?? '').trim().isNotEmpty) {
        val.dob = dob!.trim();
      }
      if ((addressLine1 ?? '').trim().isNotEmpty ||
          (addressLine2 ?? '').trim().isNotEmpty ||
          (state ?? '').trim().isNotEmpty ||
          (country ?? '').trim().isNotEmpty) {
        val.contact ??= Contact(
          electronicAddress: ElectronicAddress(emailId: '', mobileNo: ''),
          physicalAddress: PhysicalAddress(
            country: '',
            addressLine1: '',
            addressLine2: '',
            state: '',
          ),
        );
        val.contact?.physicalAddress ??= PhysicalAddress(
          country: '',
          addressLine1: '',
          addressLine2: '',
          state: '',
        );
        if ((addressLine1 ?? '').trim().isNotEmpty) {
          val.contact?.physicalAddress?.addressLine1 = addressLine1!.trim();
        }
        if ((addressLine2 ?? '').trim().isNotEmpty) {
          val.contact?.physicalAddress?.addressLine2 = addressLine2!.trim();
        }
        if ((state ?? '').trim().isNotEmpty) {
          val.contact?.physicalAddress?.state = state!.trim();
        }
        if ((country ?? '').trim().isNotEmpty) {
          val.contact?.physicalAddress?.country = country!.trim();
        }
      }
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
