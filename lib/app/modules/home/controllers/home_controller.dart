import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/app/modules/shop/views/shop_view.dart';
import '../../arena/views/arena_view.dart';
import '../../profile/user_profile_view.dart';
import '../views/home_content_view.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var currentScreen = Rx<Widget>(const HomeContentView());
  
  // Cache for screens to prevent rebuilding
  final Map<int, Widget> _screenCache = {};
  
  // Performance tracking
  var isScreenTransitioning = false.obs;
  var lastScreenChangeTime = 0;
  
  // Memory management
  static const int maxCacheSize = 3;
  
  @override
  void onInit() {
    super.onInit();
    _initializeScreenCache();
  }
  
  void _initializeScreenCache() {
    // Pre-cache the most commonly used screens
    _screenCache[0] = const HomeContentView();
    _screenCache[1] = const ArenaView();
    _screenCache[2] = PastBookingsScreen();
    _screenCache[3] = const ShopView();
    _screenCache[4] = const UserProfileView();
  }

  void onItemTapped(int index) {
    // Prevent rapid tapping
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastScreenChangeTime < 300) return;
    
    if (selectedIndex.value == index) return;
    
    lastScreenChangeTime = now;
    selectedIndex.value = index;
    isScreenTransitioning.value = true;
    
    // Use cached screen if available
    if (_screenCache.containsKey(index)) {
      currentScreen.value = _screenCache[index]!;
    } else {
      // Create new screen and cache it
      final newScreen = _createScreenForIndex(index);
      _screenCache[index] = newScreen;
      currentScreen.value = newScreen;
      
      // Manage cache size
      _manageCacheSize();
    }
    
    // Reset transition flag after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      isScreenTransitioning.value = false;
    });
  }
  
  Widget _createScreenForIndex(int index) {
    switch (index) {
      case 0: 
        return const HomeContentView();
      case 1:
        return const ArenaView();
      case 2:
        return PastBookingsScreen();
      case 3:
        return const ShopView();
      case 4:
        return const UserProfileView();
      default:
        return const HomeContentView();
    }
  }
  
  void _manageCacheSize() {
    if (_screenCache.length > maxCacheSize) {
      // Remove least recently used screens
      final keysToRemove = _screenCache.keys
          .where((key) => key != selectedIndex.value)
          .take(_screenCache.length - maxCacheSize);
      
      for (final key in keysToRemove) {
        _screenCache.remove(key);
      }
    }
  }
  
  // Method to clear cache when memory is low
  void clearCache() {
    final currentIndex = selectedIndex.value;
    _screenCache.clear();
    _screenCache[currentIndex] = currentScreen.value;
  }
  
  // Method to preload specific screens
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