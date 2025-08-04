import 'dart:convert';
import 'package:get/get.dart';
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
        print('fetched user $data');
        id.value = data['user']['id'].toString();         // ✅ Ensure ID is stored correctly

        setUserData(fetchedUser);
        print("ID set: $idValue");
      } else {
        print('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Replace entire user object
  void setUserData(User fetchedUser) {
    user.value = fetchedUser;
    print("User data updated - Name: ${user.value.name}");
  }

  /// ✅ Update Google-auth fields only
  void setGoogleUserData({required String name, required String photoUrl}) {
    user.update((val) {
      val?.name = name;
      val?.photoUrl = photoUrl;
    });
    print("Google User Data set - Name: ${user.value.name}, PhotoURL: $photoUrl");
  }

  /// 👤 Getter for current User ID
  String get userId => id.value;
}
