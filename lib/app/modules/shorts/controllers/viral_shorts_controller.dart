import 'dart:convert';
import 'dart:developer';
import 'dart:math';
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
  static const _base = 'https://serpapi.com/search';

  // Multiple API keys (can add more)
  static const List<String> _apiKeys = [
    'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf',
    '5a448e4cd243fdd57fc92a6e61c3448872c7b7d82588803889c0aa45cb96af7e',
    'f5da7e32d9509302cc38341904d9a8f80ba82d5d68789c892826a25683865628',
    'cc44766411da5696ca811b64e8ce3dc89051cb19c2e01458f7f2be9b65b3cab2',
    '1192bba44b96ef7ec567bb0bbe8efc43fdc12a91f0b0343ec11c2df3b026cd6a',
    'cb4a2ea410db5d47ff0872165bd7138201fb21ad96e75957148de122491473f2',
    '2356e63291af937037ab58415767e80c2c086b676284aeb0d1b35a16b8ada363'
  ];

  /// Get a random key
  String _getRandomKey() {
    final random = Random();
    return _apiKeys[random.nextInt(_apiKeys.length)];
  }

  Future<List<YouTubeShort>> fetch(String query) async {
    final key = _getRandomKey();
    final url = '$_base?engine=youtube&search_query=$query&api_key=$key';
    final res = await http.get(Uri.parse(url));

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
    } finally {
      isLoading(false);
    }
  }
}
