import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../products_model.dart'; // Ensure you have the product model imported

class GetProductByIdController extends GetxController {
  var product = Rxn<Product>();
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  Future<void> fetchProductById(String productId) async {
    final url = '$hostName/product/$productId';
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      print('token $token');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        product.value = Product.fromJson(responseData);
      } else {
        errorMessage.value = 'Failed to fetch product';
      }
    } catch (e) {
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
