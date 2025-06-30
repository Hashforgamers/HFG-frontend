import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/services/deeplink_service.dart';
import 'package:hash/services/notification_service.dart';
import 'package:hash/config/flavor_config.dart';
import 'app/data/services/user_controller.dart';
import 'app/modules/arena/controllers/booking_controller.dart';
import 'app/modules/game/views/game_section_view.dart';
import 'app/modules/payment/razorpay_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import '/themes/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize flavor configuration for development
  FlavorConfig(
    flavor: Flavor.dev,
    appName: 'HFG Dev',
    baseUrls: {
      'userOnboard': 'https://hfg-user-onboard-3nzn.onrender.com',
      'booking': 'https://hfg-booking-hmnx.onrender.com',
      'dashboard': 'https://hfg-dashboard.onrender.com',
      'login': 'https://hfg-login-1d4c.onrender.com',
      'vendor': 'https://hfg-onboard-hqqb.onrender.com',
      // Add more as needed
    },
    appId: 'com.hfg.hash.dev',
    bundleId: 'com.hfg.hash.dev',
    appIcon: 'assets/icons/app_icon_dev.png',
    primaryColor: Colors.blue,
    accentColor: Colors.blueAccent,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup service locator first before any controllers that depend on it
  await setupServiceLocator();
  
  Get.put(UserController());
  Get.put(RazorpayController());
  Get.put(BookingController());
  Get.put(GamesController(), permanent: true);
  Get.put(NotificationController());
  Get.put(DeepLinkController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: true, // Show debug banner for dev
      title: FlavorConfig.instance.appName,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,
    );
  }
} 