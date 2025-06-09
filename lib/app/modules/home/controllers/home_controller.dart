import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/app/modules/shop/views/shop_view.dart';
import '../../arena/views/arena_view.dart';
import '../../profile/user_profile_view.dart';
import '../views/home_content_view.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var currentScreen = Rx<Widget>(HomeContentView());

  void onItemTapped(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0: 
        currentScreen.value = HomeContentView();
        break;
      case 1:
        currentScreen.value = const ArenaView();
        break;
      case 2:
        currentScreen.value = PastBookingsScreen();
        break;
      case 3:
        currentScreen.value = const ShopView();
        break;
      case 4:
        currentScreen.value = const UserProfileView();
        break;
    }
  }
}
