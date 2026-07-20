import 'package:get/get.dart';

import '../controllers/my_tournaments_controller.dart';

class MyTournamentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyTournamentsController>(() => MyTournamentsController());
  }
}
