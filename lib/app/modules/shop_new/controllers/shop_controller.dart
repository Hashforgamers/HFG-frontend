import 'package:get/get.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/utils/app_logger.dart';

class ShopController extends GetxController {
  var shopMenuIndex = 0.obs;

  /// Shared by the shop screens and the shop nav bar's cart badge.
  final cart = HashStoreCartCubit();

  void setShopMenuIndex(int index) {
    shopMenuIndex.value = index;
    AppLogger.d("Shop menu changed to index: $index");
  }

  /// Called when the shop opens: fresh store config, and a badge that
  /// reflects the current account.
  void refreshCart() {
    if (!MedusaStoreService.isConfigured) return;
    MedusaStoreService.instance.refreshConfig();
    cart.fetchCart();
  }

  /// Logout: drop the previous account's cart from memory.
  void clearCart() => cart.replace(null);

  @override
  void onClose() {
    cart.close();
    super.onClose();
  }
}
