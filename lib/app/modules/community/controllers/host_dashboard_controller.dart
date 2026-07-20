import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../bindings/create_tournament_binding.dart';
import '../models/host_verification.dart';
import '../models/tournament.dart';
import '../services/community_api.dart';
import '../views/create_tournament_view.dart';

class HostDashboardController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final loading = true.obs;
  final error = RxnString();
  final verification = Rxn<HostVerification>();
  final hosted = <TournamentListItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _api.getMyHostVerification(),
        _api.myTournaments(role: 'hosted'),
      ]);
      final host = results[0] as HostVerification?;
      if (host == null) {
        verification.value = host;
        error.value = 'Complete host registration to access Host HQ.';
        return;
      }
      if (host.status == HostVerificationStatus.suspended) {
        verification.value = host;
        error.value = 'This host account is currently suspended.';
        return;
      }
      verification.value = host;
      hosted.assignAll(results[1] as List<TournamentListItem>);
    } catch (_) {
      error.value = 'Could not load your host dashboard. Pull to retry.';
    } finally {
      loading.value = false;
    }
  }

  int get totalPlayers => hosted.fold(
    0,
    (sum, item) => sum + item.tournament.registeredPlayersCount,
  );

  double get totalCollection =>
      hosted.fold(0, (sum, item) => sum + item.tournament.totalCollection);

  double get totalCommission => hosted.fold(
    0,
    (sum, item) => sum + item.tournament.organizerCommissionAmount,
  );

  int get activeTournaments => hosted.where((item) {
    final status = item.tournament.status;
    return status == 'published' ||
        status == 'registration_open' ||
        status == 'ongoing';
  }).length;

  void openTournament(Tournament tournament) => Get.toNamed(
    AppRoutes.TOURNAMENT_DETAIL,
    arguments: {'id': tournament.id, 'can_manage': true},
  );

  void openAllTournaments() => Get.toNamed(AppRoutes.MY_TOURNAMENTS);

  Future<void> createTournament() async {
    final result = await Get.to(
      () => const CreateTournamentView(),
      binding: CreateTournamentBinding(),
      routeName: AppRoutes.CREATE_TOURNAMENT,
    );
    if (result is Tournament) await load();
  }

  void openOnboarding() => Get.offNamed(AppRoutes.HOST_ONBOARDING);
}
