// Dev-only: opens the Hash Store straight away, no login, against the mock.
//
//   python3 tool/mock_medusa/server.py
//   flutter run -t tool/mock_medusa/store_preview.dart \
//     --dart-define=MEDUSA_BASE_URL=http://localhost:9000
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/app/modules/shop_new/view/shop_view.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  locator.registerSingleton(await SharedPreferences.getInstance());
  locator.registerSingleton(AuthDataRepository());
  // The mock accepts any HFG token.
  await locator<AuthDataRepository>().saveTokens(
    accessToken: 'preview',
    refreshToken: 'preview',
  );
  final shop = Get.put(ShopController());
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const ShopMenuView(),
        bottomNavigationBar: Obx(
          () => NavigationBar(
            backgroundColor: Colors.black,
            selectedIndex: const [
              0,
              2,
              3,
            ].indexOf(shop.shopMenuIndex.value).clamp(0, 2),
            onDestinationSelected: (i) =>
                shop.setShopMenuIndex(const [0, 2, 3][i]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront_rounded),
                label: 'Store',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_rounded),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
