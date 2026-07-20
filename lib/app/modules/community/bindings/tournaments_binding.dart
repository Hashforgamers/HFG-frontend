import 'package:get/get.dart';

import '../controllers/tournaments_controller.dart';
import '../controllers/tournament_detail_controller.dart';

class TournamentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TournamentsController>(() => TournamentsController());
  }
}

class TournamentDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TournamentDetailController>(
      () => TournamentDetailController(),
    );
  }
}
