import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/user_controller.dart';

class SplashController extends GetxController {
  final UserController userController = Get.find();
  final segmentService = locator<SegmentSdkService>();

  @override
  void onReady() {
    super.onReady();
    // Track app launch event
    segmentService.onAppLaunch();
    Future.delayed(const Duration(seconds: 3), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_data');

    if (token != null && token.isNotEmpty) {
      // User is logged in, fetch their data
      await _fetchUserDataIfNeeded();
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  Future<void> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await userController.fetchUserData(currentUser.uid);
        print('✅ User data fetched in splash screen');
      } catch (e) {
        print('❌ Error fetching user data in splash: $e');
      }
    }
  }
}
