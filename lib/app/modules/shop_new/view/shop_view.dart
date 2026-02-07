import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import '../../hash_store/pages/categories_view.dart';
import '../../hash_store/pages/hash_store_cart_view.dart';
import '../../hash_store/pages/hash_store_home_page.dart';
import '../../hash_store/pages/hash_store_orders_view.dart';

class ShopMenuView extends GetView<ShopController> {
  const ShopMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final index = controller.shopMenuIndex.value;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildShopSection(index),
        );
      }),
    );
  }

  Widget _buildShopSection(int index) {
    switch (index) {
      case 0:
        return const HashStoreHomePage(key: ValueKey('shop_home'));
      case 1:
        return const CategoriesView(key: ValueKey('shop_categories'));
      case 2:
        return const HashStoreCartView(key: ValueKey('shop_cart'));
      case 3:
        return const HashStoreOrdersView(key: ValueKey('shop_orders'));
      default:
        return const HashStoreHomePage(key: ValueKey('shop_default'));
    }
  }
}
