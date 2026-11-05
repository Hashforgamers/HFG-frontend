import 'package:get/get.dart';

import 'verification_checkout_controller.dart';

class VerificationCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerificationCheckoutController>(
      () => VerificationCheckoutController(),
    );
  }
}
