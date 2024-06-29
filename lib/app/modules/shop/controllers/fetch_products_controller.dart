import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../products_model.dart';

class ProductsController extends GetxController {
  var products = <Product>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const url = '$hostName/products';
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('products$responseData');

        if (responseData is List) {
          products.value = responseData.map((json) => Product.fromJson(json)).toList();
        } else {
          errorMessage.value = 'Unexpected response format';
        }
      } else {
        errorMessage.value = 'Failed to fetch products';
      }
    } catch (e) {
      print(e);

      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
}
