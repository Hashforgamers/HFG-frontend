import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/core/utils/haptics.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final HomeController controller = Get.find();
  final ShopController shopController = Get.find<ShopController>();

  void _openShopSection(int sectionIndex) {
    if (!HomeController.isHashShopReleased) {
      controller.onItemTapped(2);
      return;
    }
    final wasClosed = !controller.isShopOpen.value;
    if (controller.selectedIndex.value != 2) {
      controller.onItemTapped(2);
    }
    controller.isShopOpen.value = true;
    shopController.setShopMenuIndex(sectionIndex);
    if (wasClosed) {
      Haptics.medium();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Read tabIndex argument if provided (default = 0)
    final args = Get.arguments;
    if (args != null && args['tabIndex'] != null) {
      final int targetIndex = args['tabIndex'] as int;
      if (controller.selectedIndex.value != targetIndex) {
        Future.microtask(() => controller.onItemTapped(targetIndex));
      }
    }
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Obx(() {
          return RepaintBoundary(
            key: ValueKey(controller.selectedIndex.value),
            child: controller.currentScreen.value,
          );
        }),
      ),

      // --- Bottom bar with Hash Shop slide animation ---
      bottomNavigationBar: Obx(() {
        final bool isShopMenuOpen = controller.isShopOpen.value;
        final int activeShopIndex = shopController.shopMenuIndex.value;

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // --- Bottom Navigation Bar ---
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              enableFeedback: true,
              currentIndex: controller.selectedIndex.value,
              onTap: (index) {
                if (!controller.isScreenTransitioning.value) {
                  if (index == 2 && HomeController.isHashShopReleased) {
                    if (!isShopMenuOpen) {
                      Haptics.medium();
                    }
                    shopController.setShopMenuIndex(0);
                  }
                  controller.onItemTapped(index);
                }
              },
              selectedFontSize: 0,
              unselectedFontSize: 0,
              backgroundColor: Colors.black,
              selectedItemColor: const Color(0xff338125),
              unselectedItemColor: Colors.grey[800],
              items: <BottomNavigationBarItem>[
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (1).png',
                  isSelected: controller.selectedIndex.value == 0,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/maki_gaming.png',
                  isSelected: controller.selectedIndex.value == 1,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Group.png',
                  isSelected: controller.selectedIndex.value == 2,
                  isSpecial: true,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/trophy.png',
                  isSelected: controller.selectedIndex.value == 3,
                ),
                _buildNavigationItem(
                  'assets/navbar_icons/Vector (3).png',
                  isSelected: controller.selectedIndex.value == 4,
                ),
              ],
            ),

            // --- Slide-in Hash Shop Bar ---
            if (HomeController.isHashShopReleased)
              Positioned(
                right: 0,
                bottom: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isShopMenuOpen ? 0 : 24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      width: isShopMenuOpen
                          ? MediaQuery.of(context).size.width
                          : 84,
                      height: isShopMenuOpen ? 52 : 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(isShopMenuOpen ? 0 : 24),
                        ),
                        gradient: isShopMenuOpen
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF0B1B08),
                                  Color(0xFF12351E),
                                  Color(0xFF4A2D7A),
                                  Color(0xFF7A44C0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.03),
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFF7A44C0).withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                          BoxShadow(
                            color: const Color(0xFF56C785).withValues(
                              alpha: 0.14,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isShopMenuOpen ? 10 : 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.selectedIndex.value == 2 &&
                                    isShopMenuOpen) {
                                  controller.onItemTapped(0);
                                } else {
                                  _openShopSection(0);
                                }
                              },
                              child: Row(
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    opacity: isShopMenuOpen ? 1 : 0,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.arrow_back_ios_new_sharp,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isShopMenuOpen ? "HOME" : "HASH\nSHOP",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              width: isShopMenuOpen
                                  ? (MediaQuery.of(context).size.width - 140)
                                        .clamp(0.0, double.infinity)
                                  : 0,
                              margin: EdgeInsets.only(
                                left: isShopMenuOpen ? 8 : 0,
                              ),
                              child: IgnorePointer(
                                ignoring: !isShopMenuOpen,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isShopMenuOpen ? 1 : 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _shopIcon(
                                        Icons.storefront_rounded,
                                        isActive: activeShopIndex == 0,
                                        onTap: () => _openShopSection(0),
                                      ),
                                      _shopIcon(
                                        Icons.dashboard_customize_rounded,
                                        isActive: activeShopIndex == 1,
                                        onTap: () => _openShopSection(1),
                                      ),
                                      _shopIcon(
                                        Icons.shopping_bag_rounded,
                                        isActive: activeShopIndex == 2,
                                        onTap: () => _openShopSection(2),
                                      ),
                                      _shopIcon(
                                        Icons.receipt_long_rounded,
                                        isActive: activeShopIndex == 3,
                                        onTap: () => _openShopSection(3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  // --- BottomNavigationBar Item Builder ---
  BottomNavigationBarItem _buildNavigationItem(
    String iconPath, {
    required bool isSelected,
    bool isSpecial = false,
  }) {
    final selected = controller.selectedIndex.value == 3
        ? Color(0xffFBA544)
        : Color(0xff338125);
    final unselected = Colors.grey[800];

    if (isSpecial) {
      return BottomNavigationBarItem(
        backgroundColor: Colors.black,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSelected ? 27 : 25,
          width: isSelected ? 27 : 25,
          child: Image.asset(
            iconPath,
            height: 12,
            color: isSelected ? selected : unselected,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        label: '',
      );
    }

    return BottomNavigationBarItem(
      backgroundColor: Colors.black,
      icon: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Image.asset(
          iconPath,
          height: 22,
          color: isSelected ? selected : unselected,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
      label: '',
    );
  }

  // --- Shop Icons ---
  Widget _shopIcon(
    IconData icon, {
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final activeBg = LinearGradient(
      colors: [
        const Color(0xFF3CD17F).withValues(alpha: 0.22),
        const Color(0xFF7A44C0).withValues(alpha: 0.20),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive ? activeBg : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFFA78BFF).withValues(alpha: 0.46)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFFECE3FF) : Colors.white,
          size: isActive ? 21 : 20,
        ),
      ),
    );
  }
}
