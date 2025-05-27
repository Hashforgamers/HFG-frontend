import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/amplitude_service.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  final _amplitudeService = serviceLocator<AmplitudeService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() {
          // Track screen view
          _amplitudeService.trackScreenView(
            screenName: controller.currentScreen.value.toString(),
          );
          return controller.currentScreen.value;
        }),
      ),
      bottomNavigationBar: Obx(() {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: true,
          currentIndex: controller.selectedIndex.value,
          onTap: (index) async {
            await _amplitudeService.trackNavigation(
              fromScreen: controller.currentScreen.value.toString(),
              toScreen: _getScreenName(index),
            );
            controller.onItemTapped(index);
          },
          selectedFontSize: 0,
          unselectedFontSize: 0,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/home-02.png', scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/home-02.png', scale: 2.5, color: Color(0xffDE3A3A)),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/target-04.png', scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/target-04.png', scale: 2.5, color: Color(0xffDE3A3A)),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/gaming-pad-01.png', scale: 2.5, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/gaming-pad-01.png', scale: 2.1, color: Color(0xffDE3A3A)),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/shopping-bag-01.png', scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/shopping-bag-01.png', scale: 2.5, color: Color(0xffDE3A3A)),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/settings-02.png', scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/settings-02.png', scale: 2.5, color: Color(0xffDE3A3A)),
            ),
          ],
        );
      }),
    );
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Target';
      case 2:
        return 'Games';
      case 3:
        return 'Shop';
      case 4:
        return 'Settings';
      default:
        return 'Unknown';
    }
  }
}
