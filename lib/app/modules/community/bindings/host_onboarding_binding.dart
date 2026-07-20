import 'package:get/get.dart';

import '../controllers/host_onboarding_controller.dart';

class HostOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HostOnboardingController>(() => HostOnboardingController());
  }
}
