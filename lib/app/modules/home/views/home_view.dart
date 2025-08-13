import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  final HomeController controller = Get.find();

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: Obx(() {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            enableFeedback: true,
            currentIndex: controller.selectedIndex.value,
            onTap: controller.isScreenTransitioning.value 
                ? null 
                : controller.onItemTapped,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xff338125),
            unselectedItemColor: Colors.grey[800],
            items: <BottomNavigationBarItem>[
              _buildNavigationItem(
                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/home-02_z5zoia.png',
                isSelected: controller.selectedIndex.value == 0,
              ),
              _buildNavigationItem(
                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png',
                isSelected: controller.selectedIndex.value == 1,
              ),
              _buildNavigationItem(
                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/bookings_rlxzgf.png',
                isSelected: controller.selectedIndex.value == 2,
                isSpecial: true,
              ),
              _buildNavigationItem(
                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/shopping-bag-01_fma4hs.png',
                isSelected: controller.selectedIndex.value == 3,
              ),
              _buildNavigationItem(
                'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/settings-02_uoux0w.png',
                isSelected: controller.selectedIndex.value == 4,
              ),
            ],
          ),
        );
      }),
    );
  }

  BottomNavigationBarItem _buildNavigationItem(
    String iconPath, {
    required bool isSelected,
    bool isSpecial = false,
  }) {
    if (isSpecial) {
      return BottomNavigationBarItem(
        backgroundColor: Colors.black,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSelected ? 27 : 25,
          width: isSelected ? 27 : 25,
          child: CachedNetworkImage(
            color: isSelected ? const Color(0xff338125) : Colors.grey[800],
            imageUrl: iconPath,
            placeholder: (_, _) =>
                const Center(child: RainbowGlowingLoader(size: 10)),
            errorWidget: (_, _, _) =>
                const Icon(Icons.error, color: Colors.red),
          ),
        ),
        label: '',
      );
    }

    return BottomNavigationBarItem(
      backgroundColor: Colors.black,
      icon: AnimatedScale(
        scale: isSelected ? 0.83 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: CachedNetworkImage(
          imageUrl: iconPath,
          scale: isSelected ? 2.5 : 3,
          color: isSelected ? const Color(0xff338125) : Colors.grey[800],
          placeholder: (_, _) =>
              const Center(child: RainbowGlowingLoader(size: 10)),
          errorWidget: (_, _, _) =>
              const Icon(Icons.error, color: Colors.red),
        ),
      ),
      label: '',
    );
  }
}
