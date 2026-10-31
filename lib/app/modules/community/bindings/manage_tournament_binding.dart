import 'package:get/get.dart';

import '../controllers/manage_tournament_controller.dart';

class ManageTournamentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageTournamentController>(() => ManageTournamentController());
  }
}
