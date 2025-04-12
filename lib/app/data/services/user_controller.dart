import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class UserController extends GetxController {
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

  var isLoading = false.obs;

  // Method to fetch user data from the API
  Future<void> fetchUserData(String fid) async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('https://hfg-user-onboard.onrender.com/api/users/fid/$fid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        User fetchedUser = User.fromJson(data);
        setUserData(fetchedUser);
      } else {
        print('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Set user data from API
  void setUserData(User fetchedUser) {
    user.value = fetchedUser;
    print("User data updated - Name: ${user.value.name}");
  }


  // Existing method for Google Sign-In
  void setGoogleUserData({required String name, required String photoUrl}) {
    user.update((val) {
      val?.name = name;      // Update the name field
      val?.photoUrl = photoUrl; // Update the photoUrl field
    });
    print("Google User Data set - Name: ${user.value.name}, PhotoURL: $photoUrl");
  }
}
