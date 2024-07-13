import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../products_model.dart';

class CartController extends GetxController {
  var isLoading = false.obs;
  var cartItems = <CartItem>[].obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  Future<void> addToCart(String productId, int quantity) async {
    isLoading(true);
    final token = await _getToken();
    const url = '$hostName/cart';

    final body = jsonEncode({
      "product_id": productId,
      "quantity": quantity,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      final responseData = json.decode(response.body);
      print(responseData);
      if (response.statusCode == 200) {
        successMessage.value = responseData['message'];
        await fetchCart();
      } else {
        errorMessage.value = 'Failed to add to cart';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCart() async {
    isLoading(true);
    final token = await _getToken();
    const url = '$hostName/cart';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> items = responseData['items'];
        cartItems.value = items.map((json) => CartItem.fromJson(json)).toList();


      } else {
        errorMessage.value = 'Failed to fetch cart';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCartItem(String productId) async {
    isLoading(true);
    final token = await _getToken();
    final url = '$hostName/cart/item/$productId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        await fetchCart();
      } else {
        errorMessage.value = 'Failed to delete item from cart';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
}

class CartItem {
  final String productId;
  final int quantity;

  CartItem({required this.productId, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'],
      quantity: json['quantity'],
    );
  }
}
