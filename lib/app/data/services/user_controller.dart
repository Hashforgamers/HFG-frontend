import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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
  ).obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> fetchUserData() async {
    final authToken = await _getToken();

    const String url = '$hostName/user';

    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        user.value = User.fromJson(json.decode(response.body));
      } else {
        Get.snackbar('Error', 'Failed to fetch user data');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred');
    } finally {
      isLoading(false);
    }
  }
}
