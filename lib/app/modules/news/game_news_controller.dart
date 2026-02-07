// lib/app/modules/shorts/controllers/game_news_controller.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hash/config/app_keys.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';

/// Minimal model
class GameNewsItem {
  final String title;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? source;

  GameNewsItem({
    required this.title,
    required this.url,
    this.imageUrl,
    this.publishedAt,
    this.source,
  });

  factory GameNewsItem.fromJson(Map<String, dynamic> j) {
    return GameNewsItem(
      title: (j['title'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      imageUrl: (j['urlToImage'] ?? '').toString().isEmpty ? null : j['urlToImage'],
      publishedAt: j['publishedAt'] != null ? DateTime.tryParse(j['publishedAt']) : null,
      source: (j['source']?['name'] ?? '').toString(),
    );
  }
}

class NewsController extends GetxController {
  final isLoading = false.obs;
  final items = <GameNewsItem>[].obs;

  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _busy = false;

  final Set<String> _seen = <String>{};
  final Dio _dio = locator<NetworkProvider>().noAuth();
  final List<String> _apiKeys = AppKeys.newsApiKeys;

  final _rnd = Random();

  String? _getRandomKey() {
    if (_apiKeys.isEmpty) return null;
    return _apiKeys[_rnd.nextInt(_apiKeys.length)];
  }


  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_busy) return;
    _busy = true;
    isLoading.value = true;
    _page = 1;
    _hasMore = true;
    _seen.clear();
    items.clear();

    try {
      final batch = await _fetchPage(_page);
      items.addAll(batch);
      _silentPrefetchNext();
    } finally {
      isLoading.value = false;
      _busy = false;
    }
  }

  Future<void> loadMore() async {
    if (_busy || !_hasMore) return;
    _busy = true;
    try {
      final next = _page + 1;
      final batch = await _fetchPage(next);
      if (batch.isEmpty) {
        _hasMore = false;
      } else {
        _page = next;
        items.addAll(batch);
        _silentPrefetchNext();
      }
    } finally {
      _busy = false;
    }
  }

  Future<List<GameNewsItem>> _fetchPage(int page) async {
    final uri = Uri.parse(
      'https://newsapi.org/v2/everything'
          '?q=(gaming OR "video game" OR esports)'
          '&language=en'
          '&sortBy=publishedAt'
          '&pageSize=$_pageSize'
          '&page=$page',
    );

    final key = _getRandomKey(); // pick a random key each call
    if (key == null) {
      if (kDebugMode) {
        AppLogger.w('NEWS_API_KEYS not set; skipping news fetch.');
      }
      return const [];
    }

    final res = await _dio.get(
      uri.toString(),
      options: Options(headers: {'X-Api-Key': key}),
    );
    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('NewsAPI error ${res.statusCode}: ${res.data}');
      }
      AppLogger.d(res.data);
      return const [];
    }

    final data = res.data is String
        ? json.decode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    if (data['status'] != 'ok') return const [];

    final list = (data['articles'] as List? ?? const [])
        .map((e) => GameNewsItem.fromJson(e as Map<String, dynamic>))
        .where((a) => a.title.isNotEmpty && a.url.isNotEmpty)
        .where((a) => _seen.add(a.url))
        .toList();

    return list;
  }

  void _silentPrefetchNext() {
    Future.microtask(() async {
      if (_hasMore && !_busy) {
        try {
          await _fetchPage(_page + 1);
        } catch (_) {}
      }
    });
  }

  bool get hasMore => _hasMore;
}
