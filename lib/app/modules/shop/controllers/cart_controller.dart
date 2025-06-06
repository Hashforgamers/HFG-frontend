import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';


class CartController extends GetxController {
  var isLoading = false.obs;
  var cartItems = <CartItem>[].obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  Future<void> addToCart(String productId, int quantity) async {
    isLoading(true);
    try {
      final response = await _remoteRepo.addToCart(
        productId: productId,
        quantity: quantity,
      );
      successMessage.value = response['message'];
      await fetchCart();
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCart() async {
    isLoading(true);
    try {
      final items = await _remoteRepo.fetchCart();
      cartItems.value = items.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCartItem(String productId) async {
    isLoading(true);
    try {
      await _remoteRepo.deleteCartItem(productId);
      await fetchCart();
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
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
