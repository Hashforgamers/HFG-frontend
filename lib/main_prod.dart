import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hash/app/modules/fcm/cubit/fcm_cubit.dart';
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/utils/scroll_behaviour.dart';
import 'app/data/services/user_controller.dart';
import 'app/modules/arena/controllers/booking_controller.dart';
import 'app/modules/game/views/game_section_view.dart';
import 'app/modules/payment/razorpay_controller.dart';
import 'app/modules/wallet/controllers/wallet_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import '/themes/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flavor configuration for production
  FlavorConfig(
    flavor: Flavor.prod,
    appName: 'HFG',
    baseUrls: {
      'userOnboard': 'https://hfg-user-onboard.onrender.com',
      'booking': 'https://hfg-booking.onrender.com',
      'dashboard': 'https://hfg-dashboard.onrender.com',
      'login': 'https://hfg-login.onrender.com',
      'vendor': 'https://hfg-onboard.onrender.com',
      // Add more as needed
    },
    appId: 'com.hfg.hash',
    bundleId: 'com.hfg.hash',
    appIcon: 'assets/icons/app_icon.png',
    primaryColor: Colors.purple,
    accentColor: Colors.purpleAccent,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup service locator first before any controllers that depend on it
  await setupServiceLocator();

  Get.put(UserController());
  Get.put(RazorpayController());
  Get.put(BookingController());
  Get.put(GamesController(), permanent: true);
  Get.put(NotificationController());
  Get.put(DeepLinkController());
  // Register WalletController after UserController to ensure dependency is available
  Get.put(WalletController());

  runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => HashCoinCubit(),
            ),
        BlocProvider(
          create: (context) => FcmCubit(),
        ),
        BlocProvider(
          create: (context) =>  GamePassCubit(),),
          ],
          child: ScrollConfiguration(
            behavior: NoGlowScrollBehavior(),
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false, // Hide debug banner for prod
              title: FlavorConfig.instance.appName,
              theme: AppTheme.dark,
              initialRoute: AppRoutes.SPLASH,
              getPages: AppPages.pages,
            ),
          ),
        );
      },
    );
  }
}
