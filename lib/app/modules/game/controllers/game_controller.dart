import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../views/game_section_view.dart';

class GamesController extends GetxController {
  final games = <Game>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (games.isEmpty) fetchGames();
  }

  void fetchGames() async {
    if (isLoading.value || games.isNotEmpty) return;
    try {
      isLoading(true);
      // Your game fetching logic here
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch games', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }
} 