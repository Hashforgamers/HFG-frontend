import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() {
          return controller.currentScreen.value;
        }),
      ),
      bottomNavigationBar: Obx(() {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: true,
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onItemTapped,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset(
                'assets/icons/home-02.png',
                scale: 3,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/home-02.png',
                scale: 2.5,
                color: const Color(0xff338125),
              ),
            ),
            // BottomNavigationBarItem(backgroundColor: Colors.black,
            //   icon: Image.asset('assets/icons/target-04.png',scale: 3,color: Colors.grey[800]),
            //   label: '',
            //   activeIcon: Image.asset('assets/icons/target-04.png',scale: 2.5,color: Color(0xffDE3A3A),),

            // ),

            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/gaming-pad-01.png',
                  scale: 2.5, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/gaming-pad-01.png',
                scale: 2.1,
                color: const Color(0xff338125),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: SizedBox(
                height: 25, // Adjust height
                width: 25, // Adjust width
                child: Image.asset(
                  'assets/icons/bookings.png',
                  color: Colors.grey[800],
                ),
              ),
              label: '',
              activeIcon: SizedBox(
                height: 27, // Slightly larger when active
                width: 27,
                child: Image.asset(
                  'assets/icons/bookings.png',
                  color: const Color(0xff338125),
                ),
              ),
            ),

            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/shopping-bag-01.png',
                  scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/shopping-bag-01.png',
                  scale: 2.5, color: const Color(0xff338125)),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: Image.asset('assets/icons/settings-02.png',
                  scale: 3, color: Colors.grey[800]),
              label: '',
              activeIcon: Image.asset('assets/icons/settings-02.png',
                  scale: 2.5, color: const Color(0xff338125)),
            ),
          ],
        );
      }),
    );
  }
}
