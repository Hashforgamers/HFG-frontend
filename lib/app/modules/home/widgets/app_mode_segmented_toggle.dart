import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/home/widgets/hash_segmented_switch.dart';
import 'package:hash/app/modules/live/views/hash_live_splash_screen.dart';
import 'package:hash/app/modules/splash/views/splash_view.dart';

class AppModeSegmentedToggle extends StatelessWidget {
  final bool compact;

  const AppModeSegmentedToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);

    return Obx(() {
      final selected = controller.selectedMode.value;
      return HashSegmentedSwitch(
        key: ValueKey(selected),
        options: const ['Hash Hub', 'Hash Live'],
        initialIndex: selected == AppMode.hub ? 0 : 1,
        onChanged: (index) {
          final nextMode = index == 0 ? AppMode.hub : AppMode.live;
          if (nextMode == selected) return;
          controller.setMode(nextMode);
          if (nextMode == AppMode.hub) {
            Get.offAll(
              () => SplashView(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 330),
            );
          } else {
            Get.offAll(
              () => const HashLiveSplashScreen(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 380),
            );
          }
        },
      );
    });
  }
}
