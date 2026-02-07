import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../hash_store/pages/hash_store_home_page.dart';
import '../../hash_store/pages/categories_view.dart';
import '../../hash_store/pages/hash_store_cart_view.dart';
import '../../hash_store/pages/hash_store_orders_view.dart';
import 'package:hash/core/utils/app_logger.dart';

class ShopController extends GetxController {
  var shopMenuIndex = 0.obs;

  final shopScreens = [
    const HashStoreHomePage(),
    const CategoriesView(),
    const HashStoreCartView(),
    const HashStoreOrdersView(),
  ];

  void setShopMenuIndex(int index) {
    shopMenuIndex.value = index;
    AppLogger.d("Shop menu changed to index: $index");
  }

  Widget get currentShopScreen =>
      shopScreens[shopMenuIndex.value % shopScreens.length];
}
