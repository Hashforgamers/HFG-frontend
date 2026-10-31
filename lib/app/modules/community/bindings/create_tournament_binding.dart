import 'package:get/get.dart';

import '../controllers/create_tournament_controller.dart';

class CreateTournamentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTournamentController>(() => CreateTournamentController());
  }
}
