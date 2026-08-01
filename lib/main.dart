import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hash/app/modules/fcm/cubit/fcm_cubit.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/notifications/controllers/app_notifications_controller.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service/firebase_in_app_messaging_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_notification_service.dart';
import 'package:hash/utils/scroll_behaviour.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/data/services/user_controller.dart';
import 'app/modules/arena/controllers/booking_controller.dart';
import 'app/modules/game/views/game_section_view.dart';
import 'app/modules/payment/razorpay_controller.dart';
import 'app/modules/shop_new/controllers/shop_controller.dart';
import 'app/modules/wallet/controllers/wallet_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import '/themes/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize(); // optional but prevents early access
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

  await Hive.initFlutter();
  if (!Hive.isBoxOpen('user')) {
    await Hive.openBox('user');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup service locator first before any controllers that depend on it
  await setupServiceLocator();
  unawaited(locator<FirebaseInAppMessagingService>().initialize());
  unawaited(
    locator<FbEventsService>().configureAdvertiserTrackingForIos(
      promptIfNeeded: true,
    ),
  );

  Get.put(UserController());
  Get.put(RazorpayController());
  Get.put(BookingController());
  Get.put(GamesController(), permanent: true);
  Get.put(NotificationController());
  Get.put(AppNotificationsController(), permanent: true);
  Get.put(DeepLinkController());
  // Register WalletController after UserController to ensure dependency is available
  Get.put(WalletController());
  Get.put(ShopController(), permanent: true);
  Get.put(ChatService(), permanent: true);
  Get.put(MiniGameLeaderboardNotificationService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final config = ClarityConfig(
    //   projectId: "t124gco2m1",
    //   logLevel: LogLevel
    //       .None, // Note: Use "LogLevel.Verbose" value while testing to debug initialization issues.
    // );
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HashCoinCubit()),
        BlocProvider(create: (context) => FcmCubit()),
      ],
      child: ScrollConfiguration(
        behavior: NoGlowScrollBehavior(),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: true, // Show debug banner for dev
          title: FlavorConfig.instance.appName,
          theme: AppTheme.dark,
          initialRoute: AppRoutes.SPLASH,
          getPages: AppPages.pages,
          navigatorObservers: [locator<AnalyticsService>().observer],
        ),
      ),
    );
  }
}
