import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/login/controllers/login_controller.dart';
import 'package:hash/app/modules/home/views/home_view.dart';

class HubRoot extends StatelessWidget {
  const HubRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final modeController = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);
    modeController.setMode(AppMode.hub);

    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController());
    }
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController());
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    return const HomeView();
  }
}
