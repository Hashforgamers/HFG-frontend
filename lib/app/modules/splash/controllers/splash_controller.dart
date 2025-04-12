import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(Duration(seconds: 6), () {
      _checkLoginStatus();
    });  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_data');

    if (token != null && token.isNotEmpty) {
      navigateToHome();
    } else {
      navigateToLogin();
    }
  }

  void navigateToHome() {
    Get.offAllNamed(AppRoutes.HOME);
  }

  void navigateToLogin() {
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
