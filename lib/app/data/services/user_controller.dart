import 'dart:convert';
import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:hash/core/network/api_endpoints.dart';

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

  /// 🧲 Fetch user by **ID** and store both profile and id
  Future<void> fetchUserData(String idValue) async {
    isLoading.value = true;
    final url = Uri.parse('${ApiEndpoints.checkUserExistsInAPI}$idValue');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedUser = User.fromJson(data['user']); // ✅ RIGHT
        id.value = data['user']['id']
            .toString(); // ✅ Ensure ID is stored correctly

        setUserData(fetchedUser);
      } else {}
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Replace entire user object
  void setUserData(User fetchedUser) {
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

