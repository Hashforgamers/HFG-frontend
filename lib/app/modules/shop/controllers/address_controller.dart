import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AddressController extends GetxController {
  var addresses = [].obs;
  var activeAddress = {}.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
    fetchActiveAddress();
    _getToken();
  }
  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
  Future<void> fetchAddresses() async {
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('$hostName/checkout/addresses'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        addresses.value = data['addresses'];
      } else {
        errorMessage.value = 'Failed to load addresses';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchActiveAddress() async {
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      final response = await http.get(
        Uri.parse('$hostName/checkout/address/active'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        activeAddress.value = data;
      } else {
        errorMessage.value = 'Failed to load active address';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      final response = await http.post(
        Uri.parse('$hostName/checkout/address'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
        body: json.encode(address),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        fetchAddresses();
        fetchActiveAddress();
      } else {
        errorMessage.value = 'Failed to add address';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }
}
class Address {
  String? addressLine1;
  String? addressLine2;
  String? pincode;
  String? state;
  String? country;
  String? addressType;
  bool? isActive;

  Address({this.addressLine1, this.addressLine2, this.pincode, this.state, this.country, this.addressType, this.isActive});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      pincode: json['pincode'],
      state: json['State'],
      country: json['Country'],
      addressType: json['address_type'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'pincode': pincode,
      'State': state,
      'Country': country,
      'address_type': addressType,
      'is_active': isActive,
    };
  }
}