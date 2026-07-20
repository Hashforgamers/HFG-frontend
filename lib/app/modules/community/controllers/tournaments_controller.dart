import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../models/tournament.dart';
import '../services/community_api.dart';

/// Tournament discovery — GET /tournaments with view/search filters.
class TournamentsController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final RxnString error = RxnString();
  final RxList<Tournament> items = <Tournament>[].obs;
  final RxString view = 'upcoming'.obs; // upcoming | featured | free | popular
  final RxString search = ''.obs;

  int _page = 1;
  int _pages = 1;

  static const tabs = ['upcoming', 'featured', 'free', 'popular'];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setView(String v) async {
    if (view.value == v) return;
    view.value = v;
    await load();
  }

  Future<void> setSearch(String q) async {
    search.value = q;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _page = 1;
    try {
      final res = await _api.listTournaments(
        page: _page,
        perPage: 20,
        view: view.value,
        search: search.value.isEmpty ? null : search.value,
      );
      items.assignAll(res.items);
      _pages = res.pages;
    } catch (_) {
      error.value = 'Could not load tournaments. Pull to retry.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || _page >= _pages) return;
    loadingMore.value = true;
    try {
      final res = await _api.listTournaments(
        page: _page + 1,
        perPage: 20,
        view: view.value,
        search: search.value.isEmpty ? null : search.value,
      );
      _page += 1;
      items.addAll(res.items);
    } catch (_) {
      // keep existing items
    } finally {
      loadingMore.value = false;
    }
  }

  void openDetail(Tournament t) {
    Get.toNamed(AppRoutes.TOURNAMENT_DETAIL, arguments: t);
  }
}
