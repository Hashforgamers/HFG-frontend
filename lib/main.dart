import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/services/deeplink_service.dart';
import 'package:hash/services/notification_service.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(UserController()); // Initialize globally here
  Get.put(RazorpayController()); // Bind the controller
  Get.put(BookingController());
  Get.put(GamesController(), permanent: true);
  Get.put(NotificationController()); // Initialize the controller
  Get.put(DeepLinkController()); // Add this

// Register the controller
  await setupServiceLocator();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter GetX App',
      theme: AppTheme.dark,
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,
    );
  }
}
