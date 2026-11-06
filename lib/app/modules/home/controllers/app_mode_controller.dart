import 'package:get/get.dart';

enum AppMode { hub, live }

class AppModeController extends GetxController {
  final Rx<AppMode> selectedMode = AppMode.hub.obs;

  void setMode(AppMode mode) {
    if (selectedMode.value == mode) return;
    selectedMode.value = mode;
  }
}
