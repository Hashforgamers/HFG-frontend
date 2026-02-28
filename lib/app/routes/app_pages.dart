import 'package:get/get.dart';
import 'package:hash/app/modules/chat/views/chat_inbox_view.dart';
import 'package:hash/app/modules/notifications/views/notifications_view.dart';
import 'package:hash/app/modules/shop/views/shop_view.dart';
import 'package:hash/app/modules/tournaments/views/tournament_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/signup/views/signup_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/wallet/views/wallet_view.dart';
import '../modules/need_help/need_help_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => OnboardingScreen(),
      // binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(name: AppRoutes.PAGE1, page: () => ShopView()),
    GetPage(name: AppRoutes.PAGE2, page: () => TournamentView()),
    GetPage(name: AppRoutes.SIGNUP, page: () => SignUpView()),
    GetPage(name: AppRoutes.WALLET, page: () => const WalletPage()),
    GetPage(name: AppRoutes.NEED_HELP, page: () => const NeedHelpPage()),
    GetPage(name: AppRoutes.CHAT, page: () => const ChatInboxView()),
    GetPage(
      name: AppRoutes.NOTIFICATIONS,
      page: () => const NotificationsView(),
    ),
  ];
}
