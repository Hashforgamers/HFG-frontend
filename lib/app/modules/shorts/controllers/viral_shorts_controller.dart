import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hash/config/app_keys.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';

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
  final List<String> _apiKeys = AppKeys.serpApiKeys;
  final Dio _dio = locator<NetworkProvider>().noAuth();

  /// Get a random key
  String? _getRandomKey() {
    if (_apiKeys.isEmpty) return null;
    final random = Random();
    return _apiKeys[random.nextInt(_apiKeys.length)];
  }

  Future<List<YouTubeShort>> fetch(String query) async {
    final key = _getRandomKey();
    if (key == null) {
      AppLogger.w('SERPAPI_KEYS not set; skipping shorts fetch.');
      return [];
    }
    final url = '$_base?engine=youtube&search_query=$query&api_key=$key';
    final res = await _dio.get(url);

    if (res.statusCode == 200) {
      final data = res.data is String
          ? json.decode(res.data as String)
          : res.data;
      final List results = data['video_results'];
      final filtered = results.where((e) => (e['live'] ?? false) == false).toList();
      return filtered.map((e) => YouTubeShort.fromJson(e)).toList();
    }

    throw Exception('Failed to load YouTube shorts');
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
