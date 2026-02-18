import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/hash_store/pages/categories_view.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_cart_view.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_orders_view.dart';

import '../../home/controllers/home_controller.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_home_page.dart';

class HashStoreContainer extends StatelessWidget {
  const HashStoreContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx((){
      switch (controller.hashIndex.value) {
        case 0:
          return const HashStoreHomePage();
        case 1:
          return const CategoriesView();
        case 2:
          return const HashStoreCartView();
        case 3:
          return const HashStoreOrdersView();
        default:
          return const HashStoreHomePage();
      }
    });
  }
}
