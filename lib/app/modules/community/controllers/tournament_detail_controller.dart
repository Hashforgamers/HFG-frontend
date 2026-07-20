import 'package:get/get.dart';

import '../models/tournament.dart';
import '../services/community_api.dart';

/// Tournament detail + registration.
/// Uses authed detail when a session exists (for room_details), else public.
class TournamentDetailController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final Rxn<Tournament> tournament = Rxn<Tournament>();
  final RxBool loading = true.obs;
  final RxBool acting = false.obs; // register / cancel in flight
  final RxBool canManage = false.obs;
  final RxnString error = RxnString();

  late String _id;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Tournament) {
      tournament.value = arg;
      _id = arg.id;
      canManage.value = arg.canManage;
    } else if (arg is Map) {
      _id = (arg['id'] ?? '').toString();
      canManage.value = arg['can_manage'] == true;
    } else if (arg is String) {
      _id = arg;
    } else {
      _id = '';
    }
    refreshDetail();
  }

  Future<void> refreshDetail() async {
    if (_id.isEmpty) {
      loading.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      // Prefer authed detail (may include room_details); fall back to public.
      Tournament t;
      try {
        t = await _api.getTournament(_id);
      } catch (_) {
        t = await _api.getPublicTournament(_id);
      }
      tournament.value = t;
      canManage.value = canManage.value || t.canManage;
    } catch (_) {
      if (tournament.value == null) {
        error.value = 'Could not load this tournament.';
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> cancelRegistration() async {
    if (_id.isEmpty) return;
    acting.value = true;
    try {
      await _api.cancelMyRegistration(_id);
      await refreshDetail();
      Get.snackbar(
        'Registration cancelled',
        '',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Could not cancel',
        _reason(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      acting.value = false;
    }
  }

  String _reason(Object e) {
    final s = e.toString();
    if (s.contains('409')) return 'Already registered or tournament is full.';
    if (s.contains('403')) return 'Not allowed for this tournament.';
    return 'Please try again.';
  }
}
