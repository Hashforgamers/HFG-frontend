import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/home/views/hash_hub_splash_screen.dart';
import 'package:hash/app/modules/home/widgets/hash_segmented_switch.dart';
import 'package:hash/app/modules/live/views/hash_live_splash_screen.dart';
import 'package:hash/core/utils/haptics.dart';

class AppModeSegmentedToggle extends StatelessWidget {
  final bool compact;
  static bool _isSwitchingRoute = false;

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
        onChanged: (index) async {
          if (_isSwitchingRoute) return;
          final nextMode = index == 0 ? AppMode.hub : AppMode.live;
          if (nextMode == selected) return;
          _isSwitchingRoute = true;
          controller.setMode(nextMode);
          try {
            if (nextMode == AppMode.hub) {
              unawaited(
                Get.offAll(
                  () => const HashHubSplashScreen(),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 330),
                ),
              );
            } else {
              unawaited(Haptics.cta());
              unawaited(
                Get.offAll(
                  () => const HashLiveSplashScreen(),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 380),
                ),
              );
            }
          } finally {
            Future<void>.delayed(const Duration(milliseconds: 500), () {
              _isSwitchingRoute = false;
            });
          }
        },
      );
    });
  }
}
