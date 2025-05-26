import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../data/models/game_news_model.dart';

class NewsController extends GetxController {
  var isLoading = true.obs;
  var newsList = <NewsArticle>[].obs;

  final String apiKey = '78d76a751c4c6f512c25e16443178fa911653e93';

  @override
  void onInit() {
    fetchNews();
    super.onInit();
  }

  Future<void> fetchNews() async {
    try {
      final url = Uri.parse(
        'https://www.gamespot.com/api/articles/?api_key=$apiKey&format=json&limit=10',
      );
      final response = await http.get(url);
      print('newss ${response}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'];
        newsList.value = results.map((e) => NewsArticle.fromJson(e)).toList();

      } else {
        Get.snackbar("Error", "Failed to fetch news");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
