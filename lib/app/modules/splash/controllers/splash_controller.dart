import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class SplashController extends GetxController {


  void navigateToHome() async {
    // Get.offAllNamed(AppRoutes.HOME);
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
