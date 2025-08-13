import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                'assets/icons/home-02.png',
                isSelected: controller.selectedIndex.value == 0,
              ),
              _buildNavigationItem(
                'assets/icons/gaming-pad-01.png',
                isSelected: controller.selectedIndex.value == 1,
              ),
              _buildNavigationItem(
                'assets/icons/bookings.png',
                isSelected: controller.selectedIndex.value == 2,
                isSpecial: true,
              ),
              _buildNavigationItem(
                'assets/icons/shopping-bag-01.png',
                isSelected: controller.selectedIndex.value == 3,
              ),
              _buildNavigationItem(
                'assets/icons/settings-02.png',
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
          child: Image.asset(
            iconPath,
            color: isSelected ? const Color(0xff338125) : Colors.grey[800],
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
        child: Image.asset(
          iconPath,
          scale: isSelected ? 2.5 : 3,
          color: isSelected ? const Color(0xff338125) : Colors.grey[800],
        ),
      ),
      label: '',
    );
  }
}
