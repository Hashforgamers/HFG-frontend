import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Model
class YouTubeShort {
  final String title, link, thumbnail, channelName, channelImage;

  YouTubeShort({
    required this.title,
    required this.link,
    required this.thumbnail,
    required this.channelName,
    required this.channelImage,
  });

  factory YouTubeShort.fromJson(Map<String, dynamic> json) {
    return YouTubeShort(
      title:        json['title'],
      link:         json['link'],
      thumbnail:    json['thumbnail']['static'],
      channelName:  json['channel']['name'],
      channelImage: json['channel']['thumbnail'],
    );
  }
}

/// API
class ApiService {
  static const _key = 'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf';
  static const _base = 'https://serpapi.com/search';

  Future<List<YouTubeShort>> fetch(String query) async {
    final res = await http.get(Uri.parse('$_base?engine=youtube&search_query=$query&api_key=$_key'));

    if (res.statusCode == 200) {
      final List data = json.decode(res.body)['video_results'];
      final filtered = data.where((e) => (e['live'] ?? false) == false).toList();
      return filtered.map((e) => YouTubeShort.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load YouTube shorts');
    }
  }
}

/// Controller
class YouTubeShortsController extends GetxController {
  final shorts = <YouTubeShort>[].obs;
  final isLoading = true.obs;
  final _api = ApiService();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      shorts.value = await _api.fetch('Gaming Shorts');
    } catch (e) {
      log('Error: $e');
    } finally {
      isLoading(false);
    }
  }
}
