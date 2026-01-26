import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final HomeController controller = Get.find();

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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.ease,
              bottom: 5, // Just above navbar
              right: isShopMenuOpen ? 0 : -MediaQuery.of(context).size.width*0.80,
              child: ClipRRect(
                borderRadius: isShopMenuOpen
                    ? BorderRadius.zero
                    : const BorderRadius.horizontal(left: Radius.circular(20)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: MediaQuery.of(context).size.width,
                    height: isShopMenuOpen?50:45,
                    decoration: BoxDecoration(
                      borderRadius: isShopMenuOpen
                          ? BorderRadius.zero
                          : const BorderRadius.horizontal(
                        left: Radius.circular(35),
                      ),
                      gradient: isShopMenuOpen
                          ?  LinearGradient(
                        colors: [
                          Color(0xff0B1B08), // Green on left
                          Color(0xff0B1B08).withOpacity(0.6), // Green on left
                          Color(0xff7A44C0).withOpacity(0.7), // Purple on right
                          Color(0xff7A44C0).withOpacity(0.8), // Purple on right
                          Color(0xff7A44C0), // Purple on right
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                          : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                          Colors.black.withOpacity(0.25),
                        ],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: const Color(0xff7A44C0).withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),

                    // --- Inner content ---
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Hash App / Hash Shop toggle
                          GestureDetector(
                            onTap: controller.toggleShop,
                            child: Row(
                              children: [
                                if (isShopMenuOpen)
                                  const Icon(Icons.arrow_back_ios_new_sharp,
                                      size: 12, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  isShopMenuOpen ? "Home" : "HASH\nSHOP",
                                  style:  GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Shop Icons ---
                          Expanded(
                            child: Row(mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [                                const SizedBox(width: 10),

                                _shopIcon(Icons.category),
                                const SizedBox(width: 10),
                                _shopIcon(Icons.shopping_bag),
                                const SizedBox(width: 10),
                                _shopIcon(Icons.gif_box_rounded),
                                const SizedBox(width: 10),

                              ],
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
    final selected = controller.selectedIndex.value==3?Color(0xffFBA544):Color(0xff338125);
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
  Widget _shopIcon(IconData icon) {
    return Icon(icon, color: Colors.white, size: 22);
  }
}
