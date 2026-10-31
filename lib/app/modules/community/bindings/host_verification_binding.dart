import 'package:get/get.dart';

import '../controllers/host_verification_controller.dart';

class HostVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HostVerificationController>(() => HostVerificationController());
  }
}
