import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../models/tournament.dart';
import '../services/community_api.dart';

/// "My Tournaments" — GET /me/tournaments?role=joined | hosted.
class MyTournamentsController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final RxBool loading = true.obs;
  final RxnString error = RxnString();
  final RxList<TournamentListItem> joined = <TournamentListItem>[].obs;
  final RxList<TournamentListItem> hosted = <TournamentListItem>[].obs;

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
        _api.myTournaments(role: 'joined'),
        _api.myTournaments(role: 'hosted'),
      ]);
      joined.assignAll(results[0]);
      hosted.assignAll(results[1]);
    } catch (e) {
      final s = e.toString();
      if (s.contains('No access token') || s.contains('401')) {
        error.value = 'Sign in to see your tournaments.';
      } else {
        error.value = 'Could not load your tournaments. Pull to retry.';
      }
    } finally {
      loading.value = false;
    }
  }

  void openDetail(Tournament t) =>
      Get.toNamed(AppRoutes.TOURNAMENT_DETAIL, arguments: t);
}
