import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_product_page.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';

/// Shop tab for a link section, matching `ShopMenuView`'s IndexedStack.
@visibleForTesting
int storeTabFor(String section) => switch (section) {
  'cart' => 2,
  'orders' || 'order' => 3,
  _ => 0,
};

/// Opens the shop overlay on home at the right tab, then the product or
/// order on top of it. Call with home as the current route.
Future<void> openStoreLink(String section, String? resource) async {
  final shop = Get.find<ShopController>();
  final home = Get.find<HomeController>();
  shop.setShopMenuIndex(storeTabFor(section));
  if (!home.isShopOpen.value) {
    home.isShopOpen.value = true;
    shop.refreshCart();
  }
  if (resource == null) return;
  if (section == 'order') {
    await Get.to(() => HashStoreOrderPage(orderId: resource));
    return;
  }
  if (section == 'product') {
    try {
      final product = await MedusaStoreService.instance.product(resource);
      if (product == null) {
        storeToast('This product is no longer available.', error: true);
        return;
      }
      await Get.to(
        () => BlocProvider.value(
          value: shop.cart,
          child: HashStoreProductPage(product: product),
        ),
      );
    } catch (e) {
      storeToast(e.toString(), error: true);
    }
  }
}
