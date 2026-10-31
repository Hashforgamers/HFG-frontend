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
    String asString(dynamic value) => (value ?? '').toString().trim();

    final dynamic thumbnailRaw = json['thumbnail'];
    String thumbnail = '';
    if (thumbnailRaw is Map) {
      final staticThumb = asString(thumbnailRaw['static']);
      thumbnail = staticThumb.isNotEmpty
          ? staticThumb
          : asString(thumbnailRaw['rich']);
    } else {
      thumbnail = asString(thumbnailRaw);
    }

    final channel = json['channel'] is Map
        ? Map<String, dynamic>.from(json['channel'])
        : const <String, dynamic>{};

    return YouTubeShort(
      title: asString(json['title']),
      link: asString(json['link']),
      thumbnail: thumbnail,
      channelName: asString(channel['name']),
      channelImage: asString(channel['thumbnail']),
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
    AppLogger.i(
      '[Shorts] Fetch started. query="$query", keys=${_apiKeys.length}',
    );
    if (key == null) {
      AppLogger.w(
        '[Shorts] SERPAPI_KEYS not set; skipping shorts fetch. Set AppKeys.serpApiKeys in lib/config/app_keys.dart.',
      );
      return [];
    }

    final url = '$_base?engine=youtube&search_query=$query&api_key=$key';
    try {
      final res = await _dio.get(url);
      AppLogger.i('[Shorts] Response status=${res.statusCode}');

      if (res.statusCode == 200) {
        final data = res.data is String
            ? json.decode(res.data as String)
            : res.data;

        if (data is! Map) {
          AppLogger.w('[Shorts] Unexpected response shape.');
          return [];
        }
        final mapData = Map<String, dynamic>.from(data);

        if (mapData['error'] != null) {
          AppLogger.w('[Shorts] API error: ${mapData['error']}');
        }

        final List<dynamic> results =
            (mapData['video_results'] as List?) ??
            (mapData['shorts_results'] as List?) ??
            const <dynamic>[];

        AppLogger.i('[Shorts] Raw results count=${results.length}');

        final filtered = results.where((e) {
          if (e is! Map) return false;
          return (e['live'] ?? false) == false;
        }).toList();

        final parsed = <YouTubeShort>[];
        for (final item in filtered) {
          if (item is! Map) continue;
          try {
            final short = YouTubeShort.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (short.link.isEmpty || short.title.isEmpty) continue;
            parsed.add(short);
          } catch (e, st) {
            AppLogger.e(
              '[Shorts] Failed to parse one short item',
              error: e,
              stackTrace: st,
            );
          }
        }

        AppLogger.i('[Shorts] Parsed shorts count=${parsed.length}');
        return parsed;
      }

      AppLogger.w('[Shorts] Non-200 response: ${res.statusCode}');
      throw Exception('Failed to load YouTube shorts');
    } on DioException catch (e, st) {
      AppLogger.e(
        '[Shorts] Network error while fetching shorts',
        error: e.response?.data ?? e.message,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.e('[Shorts] Unexpected fetch error', error: e, stackTrace: st);
      rethrow;
    }
  }
}

/// Controller
class YouTubeShortsController extends GetxController {
  final shorts = <YouTubeShort>[].obs;
  final isLoading = true.obs;
  final _api = ApiService();
  static List<YouTubeShort>? _cachedShorts;
  static DateTime? _lastFetchedAt;
  static const Duration _cacheTtl = Duration(minutes: 10);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final hasFreshCache =
          _cachedShorts != null &&
          _lastFetchedAt != null &&
          now.difference(_lastFetchedAt!) < _cacheTtl;
      if (hasFreshCache) {
        shorts.value = _cachedShorts!;
        AppLogger.i('[Shorts] Loaded from cache. count=${shorts.length}');
        return;
      }

      shorts.value = await _api.fetch('Trending Gaming Shorts');
      _cachedShorts = shorts.toList(growable: false);
      _lastFetchedAt = now;
      AppLogger.i('[Shorts] Loaded in controller. count=${shorts.length}');
    } catch (e, st) {
      AppLogger.e('[Shorts] Controller load failed', error: e, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }
}
