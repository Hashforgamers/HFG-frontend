import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../bindings/host_dashboard_binding.dart';
import '../models/host_program.dart';
import '../models/host_verification.dart';
import '../services/community_api.dart';
import '../views/host_dashboard_view.dart';

/// Drives the Host Onboarding value-prop screen.
///
/// Loads the public host program (fee + tiers) and, when a session exists,
/// the user's current verification record. The verification status decides
/// what the primary CTA does (see [onPrimaryCta]).
class HostOnboardingController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final Rxn<HostProgram> program = Rxn<HostProgram>();
  final Rxn<HostVerification> verification = Rxn<HostVerification>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      // Program is required for the screen; verification is best-effort.
      final results = await Future.wait([
        _api.getHostProgram(),
        _api.getMyHostVerification().catchError((_) => null),
      ]);
      program.value = results[0] as HostProgram?;
      verification.value = results[1] as HostVerification?;
      if (program.value == null) {
        error.value = 'Could not load the host program. Pull to retry.';
      }
    } catch (_) {
      error.value = 'Could not load the host program. Pull to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  HostVerificationStatus get status =>
      verification.value?.status ?? HostVerificationStatus.none;

  String get ctaLabel {
    switch (status) {
      case HostVerificationStatus.pending:
        return 'Verification In Review';
      case HostVerificationStatus.verified:
        return 'Go to Host Dashboard';
      case HostVerificationStatus.suspended:
        return 'Hosting Suspended';
      case HostVerificationStatus.rejected:
        return 'Re-apply for Verification';
      case HostVerificationStatus.none:
        return 'Get Verified & Start Earning';
    }
  }

  /// Pending/suspended states are terminal for the CTA (nothing to do here).
  bool get ctaEnabled =>
      status != HostVerificationStatus.pending &&
      status != HostVerificationStatus.suspended;

  void onPrimaryCta() {
    switch (status) {
      case HostVerificationStatus.verified:
        // Use a directly bound page here as well as registering the named
        // route. GetX can retain the pre-change route table during hot reload,
        // causing a newly added named route to fall back to `/` (splash).
        Get.to(
          () => const HostDashboardView(),
          binding: HostDashboardBinding(),
          routeName: AppRoutes.HOST_DASHBOARD,
        );
        return;
      case HostVerificationStatus.pending:
      case HostVerificationStatus.suspended:
        return; // button disabled
      case HostVerificationStatus.rejected:
      case HostVerificationStatus.none:
        Get.toNamed(
          AppRoutes.HOST_VERIFICATION_CHECKOUT,
          arguments: program.value,
        );
        return;
    }
  }
}
