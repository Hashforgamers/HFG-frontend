import 'package:get/get.dart';
import '../controller/refferal_controller.dart';

class ReferralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralController>(
      () => ReferralController(),
    );
  }
} 