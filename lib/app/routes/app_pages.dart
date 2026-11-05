import 'package:get/get.dart';
import 'package:hash/app/modules/chat/views/chat_inbox_view.dart';
import 'package:hash/app/modules/notifications/views/notifications_view.dart';
import 'package:hash/app/modules/shop/views/shop_view.dart';
import '../modules/tournaments/host/verification/host_onboarding_view.dart';
import '../modules/tournaments/host/verification/host_onboarding_binding.dart';
import '../modules/tournaments/host/verification/host_verification_view.dart';
import '../modules/tournaments/host/verification/host_verification_binding.dart';
import '../modules/tournaments/host/verification/verification_checkout_view.dart';
import '../modules/tournaments/host/verification/verification_checkout_binding.dart';
import '../modules/tournaments/host/host_hub_view.dart';
import '../modules/tournaments/host/tournament_editor_view.dart';
import '../modules/tournaments/host/control_room_view.dart';
import '../modules/tournaments/player/tournaments_home_view.dart';
import '../modules/tournaments/player/tournament_detail_view.dart';
import '../modules/tournaments/player/my_tournaments_view.dart';
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
  /// Safety net for any named route that is not registered below: GetX would
  /// otherwise render its own "route not found" page to the user.
  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => const HomeView(),
    binding: HomeBinding(),
  );

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
    GetPage(name: AppRoutes.SIGNUP, page: () => SignUpView()),
    GetPage(name: AppRoutes.WALLET, page: () => const WalletPage()),
    GetPage(name: AppRoutes.NEED_HELP, page: () => const NeedHelpPage()),
    GetPage(name: AppRoutes.CHAT, page: () => const ChatInboxView()),
    GetPage(
      name: AppRoutes.NOTIFICATIONS,
      page: () => const NotificationsView(),
    ),
    GetPage(
      name: AppRoutes.HOST_ONBOARDING,
      page: () => const HostOnboardingView(),
      binding: HostOnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.HOST_VERIFICATION,
      page: () => const HostVerificationView(),
      binding: HostVerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.HOST_VERIFICATION_CHECKOUT,
      page: () => const VerificationCheckoutView(),
      binding: VerificationCheckoutBinding(),
    ),
    GetPage(
      name: AppRoutes.HOST_DASHBOARD,
      page: () => const HostHubView(),
    ),
    GetPage(
      name: AppRoutes.CREATE_TOURNAMENT,
      page: () => const TournamentEditorView(),
    ),
    GetPage(
      name: AppRoutes.TOURNAMENTS_DISCOVERY,
      page: () => const TournamentsHomeView(),
    ),
    GetPage(
      name: AppRoutes.TOURNAMENT_DETAIL,
      page: () => const TournamentDetailView(),
    ),
    GetPage(
      name: AppRoutes.MY_TOURNAMENTS,
      page: () => const MyTournamentsView(),
    ),
    GetPage(
      name: AppRoutes.MANAGE_TOURNAMENT,
      page: () => const ControlRoomView(),
    ),
  ];
}
