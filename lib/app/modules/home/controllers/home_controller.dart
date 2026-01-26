import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/app/modules/shop/views/shop_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_home_view.dart';
import '../../arena/views/arena_view.dart';
import '../../profile/user_profile_view.dart';
import '../views/home_content_view.dart';

class HomeController extends GetxController {
  // --- Reactive states ---
  final selectedIndex = 0.obs;
  final currentScreen = Rx<Widget>(const HomeContentView());
  final isShopOpen = false.obs;
  final isScreenTransitioning = false.obs;

  // --- Performance & Cache ---
  final Map<int, Widget> _screenCache = {};
  static const int maxCacheSize = 3;
  int lastScreenChangeTime = 0;

  @override
  void onInit() {
    super.onInit();
    _initializeScreenCache();
  }

  // --- Hash Shop Slide Toggle ---
  void toggleShop() {
    // Close if open, open if closed
    if (isScreenTransitioning.value) return;
    isShopOpen.toggle();
  }

  // --- Initialize Pre-cache ---
  void _initializeScreenCache() {
    _screenCache[0] = const HomeContentView();
    _screenCache[1] = const ArenaView();
    _screenCache[2] = PastBookingsScreen();
    // _screenCache[3] = const ShopView();
    _screenCache[3] = const TournamentsHomeView();
    _screenCache[4] = const UserProfileView();
  }

  // --- Handle Bottom Navigation Tap ---
  void onItemTapped(int index) {
    // --- Debounce to avoid flicker ---
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastScreenChangeTime < 300) return;

    // --- Prevent double-tap on same tab ---
    if (selectedIndex.value == index) return;
    lastScreenChangeTime = now;

    // --- Hash Shop Handling (Middle Icon) ---
    // if (index == 2) {
    //   // Toggle slide bar instead of switching screen
    //   toggleShop();
    //   return;
    // }

    // --- Close Shop bar when navigating elsewhere ---
    if (isShopOpen.value) {
      isShopOpen.value = false;
    }

    // --- Begin transition ---
    isScreenTransitioning.value = true;
    selectedIndex.value = index;

    // --- Use cached screen or build new ---
    if (_screenCache.containsKey(index)) {
      currentScreen.value = _screenCache[index]!;
    } else {
      final newScreen = _createScreenForIndex(index);
      _screenCache[index] = newScreen;
      currentScreen.value = newScreen;
      _manageCacheSize();
    }

    // --- End transition after animation ---
    Future.delayed(const Duration(milliseconds: 100), () {
      isScreenTransitioning.value = false;
    });
  }

  // --- Create new screen if not cached ---
  Widget _createScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeContentView();
      case 1:
        return const ArenaView();
      case 2:
        return PastBookingsScreen();
      // case 3:
      //   return const ShopView();
      case 3:
        return const TournamentsHomeView();
      case 4:
        return const UserProfileView();
      default:
        return const HomeContentView();
    }
  }

  // --- Limit cache size ---
  void _manageCacheSize() {
    if (_screenCache.length > maxCacheSize) {
      final keysToRemove = _screenCache.keys
          .where((key) => key != selectedIndex.value)
          .take(_screenCache.length - maxCacheSize);
      for (final key in keysToRemove) {
        _screenCache.remove(key);
      }
    }
  }

  // --- Manual maintenance ---
  void clearCache() {
    final currentIndex = selectedIndex.value;
    _screenCache.clear();
    _screenCache[currentIndex] = currentScreen.value;
  }

  void preloadScreen(int index) {
    if (!_screenCache.containsKey(index)) {
      _screenCache[index] = _createScreenForIndex(index);
    }
  }

  @override
  void onClose() {
    _screenCache.clear();
    super.onClose();
  }
}
