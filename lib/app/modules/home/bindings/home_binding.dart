import 'package:get/get.dart';
import '../../../data/services/user_controller.dart';
import '../../arena/controllers/booking_controller.dart';
import '../../login/controllers/login_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<BookingController>(() => BookingController());
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<HomeController>(() => HomeController());

  }
}

