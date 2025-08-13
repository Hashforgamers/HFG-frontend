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
              icon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/home-02_z5zoia.png',
                size: 24,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/home-02_z5zoia.png',
                size: 30,
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
              icon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png',
                size: 28,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-01_byibeu.png',
                size: 34,
                color: const Color(0xff338125),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/bookings_rlxzgf.png',
                size: 24,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/bookings_rlxzgf.png',
                size: 30,
                color: const Color(0xff338125),
              ),
            ),

            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/shopping-bag-01_fma4hs.png',
                size: 24,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/shopping-bag-01_fma4hs.png',
                size: 30,
                color: const Color(0xff338125),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: Colors.black,
              icon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/settings-02_uoux0w.png',
                size: 24,
                color: Colors.grey[800],
              ),
              label: '',
              activeIcon: _buildIcon(
                icon:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075083/settings-02_uoux0w.png',
                size: 30,
                color: const Color(0xff338125),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildIcon({
    required String icon,
    required double size,
    required Color? color,
  }) {
    return CachedNetworkImage(
      imageUrl: icon,
      height: size, // Slightly larger when active
      width: size,
      color: color,
      placeholder: (_, _) =>
          const Center(child: RainbowGlowingLoader(size: 10)),
      errorWidget: (_, _, _) => const Icon(Icons.error, color: Colors.red),
    );
  }
}
