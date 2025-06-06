import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import '../../data/models/game_news_model.dart';

class NewsController extends GetxController {
  var isLoading = true.obs;
  var newsList = <NewsArticle>[].obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    fetchNews();
    super.onInit();
  }

  Future<void> fetchNews() async {
    try {
      final results = await _remoteRepo.fetchGameNews();
      newsList.value = results.map((e) => NewsArticle.fromJson(e)).toList();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
