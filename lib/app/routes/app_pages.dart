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
import '../modules/community/views/host_onboarding_view.dart';
import '../modules/community/bindings/host_onboarding_binding.dart';
import '../modules/community/views/host_verification_view.dart';
import '../modules/community/bindings/host_verification_binding.dart';
import '../modules/community/views/verification_checkout_view.dart';
import '../modules/community/bindings/verification_checkout_binding.dart';
import '../modules/community/views/host_dashboard_view.dart';
import '../modules/community/bindings/host_dashboard_binding.dart';
import '../modules/community/views/create_tournament_view.dart';
import '../modules/community/bindings/create_tournament_binding.dart';
import '../modules/community/views/tournaments_view.dart';
import '../modules/community/views/tournament_detail_view.dart';
import '../modules/community/bindings/tournaments_binding.dart';
import '../modules/community/views/my_tournaments_view.dart';
import '../modules/community/bindings/my_tournaments_binding.dart';
import '../modules/community/views/manage_tournament_view.dart';
import '../modules/community/bindings/manage_tournament_binding.dart';
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
      page: () => const HostDashboardView(),
      binding: HostDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.CREATE_TOURNAMENT,
      page: () => const CreateTournamentView(),
      binding: CreateTournamentBinding(),
    ),
    GetPage(
      name: AppRoutes.TOURNAMENTS_DISCOVERY,
      page: () => const TournamentsView(),
      binding: TournamentsBinding(),
    ),
    GetPage(
      name: AppRoutes.TOURNAMENT_DETAIL,
      page: () => const TournamentDetailView(),
      binding: TournamentDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.MY_TOURNAMENTS,
      page: () => const MyTournamentsView(),
      binding: MyTournamentsBinding(),
    ),
    GetPage(
      name: AppRoutes.MANAGE_TOURNAMENT,
      page: () => const ManageTournamentView(),
      binding: ManageTournamentBinding(),
    ),
  ];
}
