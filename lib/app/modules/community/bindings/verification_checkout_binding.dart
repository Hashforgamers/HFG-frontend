import 'package:get/get.dart';

import '../controllers/verification_checkout_controller.dart';

class VerificationCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerificationCheckoutController>(
      () => VerificationCheckoutController(),
    );
  }
}
