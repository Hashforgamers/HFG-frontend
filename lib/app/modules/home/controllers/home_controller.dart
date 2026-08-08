import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_home_view.dart';
import '../../arena/views/arena_view.dart';
import '../../profile/user_profile_view.dart';
import '../views/feature_coming_soon_view.dart';
import '../views/home_content_view.dart';

class HomeController extends GetxController {
  // Keep feature implementations in code, route through flags until release.
  static const bool isHashShopReleased = true;
  static const bool isTournamentReleased = true;

  // --- Reactive states ---
  final selectedIndex = 0.obs;
  final currentScreen = Rx<Widget>(const HomeContentView());
  final isShopOpen = false.obs;
  final isScreenTransitioning = false.obs;
  int _transitionStartedAt = 0;

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
    // Keep initial home load light; lazily create other heavy tabs on demand.
    _screenCache[0] = const HomeContentView();
  }

  // --- Handle Bottom Navigation Tap ---
  void onItemTapped(int index) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Failsafe: if transition flag got stuck, recover automatically.
    if (isScreenTransitioning.value && _transitionStartedAt > 0) {
      if (now - _transitionStartedAt > 900) {
        isScreenTransitioning.value = false;
      }
    }

    // --- Debounce to avoid flicker ---
    if (now - lastScreenChangeTime < 300) return;

    // Any main navigation action exits the independent Hash Shop overlay.
    if (isShopOpen.value) {
      isShopOpen.value = false;
    }

    // --- Prevent double-tap on same tab ---
    if (selectedIndex.value == index) return;
    lastScreenChangeTime = now;
    Haptics.navigation();

    // --- Begin transition ---
    isScreenTransitioning.value = true;
    _transitionStartedAt = now;
    selectedIndex.value = index;

    try {
      // --- Use cached screen or build new ---
      if (_screenCache.containsKey(index)) {
        currentScreen.value = _screenCache[index]!;
      } else {
        final newScreen = _createScreenForIndex(index);
        _screenCache[index] = newScreen;
        currentScreen.value = newScreen;
        _manageCacheSize();
      }
    } finally {
      // --- End transition after animation ---
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!isClosed) {
          isScreenTransitioning.value = false;
        }
      });
    }
  }

  // --- Create new screen if not cached ---
  Widget _createScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeContentView();
      case 1:
        return const ArenaView();
      case 2:
        return _buildTournamentScreen();
      case 3:
        return PastBookingsScreen();
      case 4:
        return const UserProfileView();
      default:
        return const HomeContentView();
    }
  }

  Widget _buildTournamentScreen() {
    if (isTournamentReleased) return const TournamentsHomeView();
    return const FeatureComingSoonView(
      title: 'Tournaments Coming Soon',
      description:
          'Tournament mode is being prepared and will be enabled in a later release.',
      icon: Icons.emoji_events_outlined,
    );
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
