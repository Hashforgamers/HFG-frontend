import 'package:get/get.dart';

import '../controllers/host_dashboard_controller.dart';

class HostDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HostDashboardController>(() => HostDashboardController());
  }
}
