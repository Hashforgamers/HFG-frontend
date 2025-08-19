// lib/app/modules/shorts/controllers/game_news_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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
  static const List<String> _apiKeys = [
    '51a460406b4c42c49acf3b06fd7aebcb',
    '8e619f80f675482fa9d9a7428ab8a3cd',
    '25f277808858445e9ad83230a2af5c4b',
    'ce0ee2717a214c128e7bb8bce624578d',
  ];

  final isLoading = false.obs;
  final items = <GameNewsItem>[].obs;

  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _busy = false;

  final Set<String> _seen = <String>{};
  final _client = http.Client();

  String _getRandomKey() {
    _apiKeys.shuffle(); // simple randomization
    return _apiKeys.first;
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

    final res = await _client.get(uri, headers: {'X-Api-Key': key});
    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('NewsAPI error ${res.statusCode}: ${res.body}');

      }
      print(res.body);
      return const [];
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
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

