import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';

import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'app/data/services/user_controller.dart';
import 'app/modules/arena/controllers/booking_controller.dart';
import 'app/modules/game/views/game_section_view.dart';
import 'app/modules/payment/razorpay_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import '/themes/app_theme.dart';
import 'firebase_options.dart'; // Make sure to include your generated Firebase options file.

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure binding for async operations

  // Initialize flavor configuration (default to dev for safety)
  FlavorConfig(
    flavor: Flavor.dev,
    appName: 'HFG Dev',
    baseUrls: {
      'userOnboard': 'https://dev-api.hfg.com',
      'booking': 'https://dev-api.hfg.com',
      'vendor': 'https://dev-api.hfg.com',
      'dashboard': 'https://dev-api.hfg.com',
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

  // Set up crash handling
  final segmentService = locator<SegmentSdkService>();

  FlutterError.onError = (FlutterErrorDetails details) {
    // Track app crash event
    segmentService.onAppCrashLogged(
      stacktrace: details.stack.toString(),
      screen: 'main',
    );

    // Log the error
    FlutterError.presentError(details);
  };

  Get.put(UserController()); // Initialize globally here
  Get.put(RazorpayController()); // Bind the controller
  Get.put(BookingController());
  Get.put(GamesController(), permanent: true);
  Get.put(NotificationController()); // Initialize the controller
  Get.put(DeepLinkController()); // Add this

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: FlavorConfig.isDevelopment(),
      title: FlavorConfig.instance.appName,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,
    );
  }
}
