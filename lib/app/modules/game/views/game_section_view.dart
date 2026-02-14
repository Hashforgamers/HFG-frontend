// Optimized GamesSection: paging + smooth scrolling + low-jank parsing & images
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hash/config/app_keys.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../../../utils/widgets/bounce_tap_widget.dart';
import '../../../../utils/widgets/loader.dart';
import 'package:hash/core/utils/app_logger.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MODEL
/// ─────────────────────────────────────────────────────────────────────────────

class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final String released; // keep string for display
  final double rating;

  const Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.released,
    required this.rating,
  });

  static Game fromJson(Map<String, dynamic> j) => Game(
    id: j['id'] ?? 0,
    name: (j['name'] ?? '').toString(),
    backgroundImage: (j['background_image'] ?? '').toString(),
    released: (j['released'] ?? 'N/A').toString(),
    rating: (j['rating'] is num) ? (j['rating'] as num).toDouble() : 0.0,
  );
}

/// Off-main isolate parser for smoother frames
List<Game> _parseGames(String body) {
  final root = json.decode(body) as Map<String, dynamic>;
  final list = (root['results'] as List? ?? const <dynamic>[]);
  return list
      .whereType<Map<String, dynamic>>()
      .map(Game.fromJson)
      .toList(growable: false);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SERVICE (paging + client reuse + timeout)
/// RAWG API: https://rawg.io/apidocs
/// ─────────────────────────────────────────────────────────────────────────────

class GameService {
  static const String _apiKey = AppKeys.rawgApiKey;
  static const String _baseUrl = 'https://api.rawg.io/api';
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.plain,
    ),
  );

  Future<({List<Game> items, bool hasMore})> fetchGames({
    required int page,
    int pageSize = 20,
  }) async {
    if (_apiKey.isEmpty) {
      AppLogger.w(
        '[GamesByDevelopers] RAWG_API_KEY is not set; skipping fetch. Add --dart-define=RAWG_API_KEY=...',
      );
      return (items: const <Game>[], hasMore: false);
    }

    final uri = Uri.parse(
      '$_baseUrl/games?key=$_apiKey&page=$page&page_size=$pageSize&ordering=-added',
    );
    AppLogger.i('[GamesByDevelopers] Fetching page=$page pageSize=$pageSize');

    try {
      final res = await _dio.get<String>(uri.toString());
      AppLogger.i('[GamesByDevelopers] Response status=${res.statusCode}');

      if (res.statusCode != 200 || res.data == null) {
        if (kDebugMode) {
          final bodySnippet = (res.data ?? '').toString();
          AppLogger.d(
            '[GamesByDevelopers] RAWG error ${res.statusCode}: ${bodySnippet.length > 250 ? bodySnippet.substring(0, 250) : bodySnippet}',
          );
        }
        return (items: const <Game>[], hasMore: false);
      }

      Map<String, dynamic> map;
      try {
        map = json.decode(res.data!) as Map<String, dynamic>;
      } catch (e, st) {
        AppLogger.e(
          '[GamesByDevelopers] Failed to decode RAWG payload',
          error: e,
          stackTrace: st,
        );
        return (items: const <Game>[], hasMore: false);
      }

      if (map['error'] != null) {
        AppLogger.w('[GamesByDevelopers] RAWG API error: ${map['error']}');
      }

      // Parse off-main-thread
      final items = await compute(_parseGames, res.data!);
      final hasMore = map['next'] != null; // detect "next" presence
      AppLogger.i(
        '[GamesByDevelopers] Parsed ${items.length} items. hasMore=$hasMore',
      );

      return (items: items, hasMore: hasMore);
    } on DioException catch (e, st) {
      AppLogger.e(
        '[GamesByDevelopers] Network error while calling RAWG',
        error: e.response?.data ?? e.message,
        stackTrace: st,
      );
      return (items: const <Game>[], hasMore: false);
    } catch (e, st) {
      AppLogger.e(
        '[GamesByDevelopers] Unexpected fetch error',
        error: e,
        stackTrace: st,
      );
      return (items: const <Game>[], hasMore: false);
    }
  }

  void dispose() {}
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CONTROLLER (GetX): pagination + prefetch + deterministic colors
/// ─────────────────────────────────────────────────────────────────────────────

class GamesController extends GetxController {
  final games = <Game>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  final _service = GameService();
  final _segmentService = locator<SegmentSdkService>();
  final _fbEventsService = locator<FbEventsService>();

  final _palette = const <Color>[
    Color(0xff710000),
    Color(0xff0e213f),
    Color(0xff37ebf3),
    Color(0xffcb1dcd),
    Color(0xff1b5e20),
    Color(0xff0d47a1),
    Color(0xff4a148c),
    Color(0xffbf360c),
    Color(0xff006064),
    Color(0xff3e2723),
  ];

  final Set<int> _seen = <int>{};
  int _page = 1;
  bool _hasMore = true;
  bool _sentPreferences = false;

  Color colorForGame(Game g) {
    // deterministic per id
    final i = (g.id.abs()) % _palette.length;
    return _palette[i];
  }

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (isLoading.value) return;
    _page = 1;
    _hasMore = true;
    _seen.clear();

    isLoading.value = true;
    try {
      final resp = await _service.fetchGames(page: _page);
      final deduped = resp.items.where((g) => _seen.add(g.id)).toList();

      games.assignAll(deduped);
      AppLogger.i(
        '[GamesByDevelopers] Initial load done. fetched=${resp.items.length} unique=${deduped.length}',
      );

      // Fire once when we have content
      if (deduped.isNotEmpty && !_sentPreferences) {
        final top = deduped.take(5).map((g) => g.name).toList(growable: false);
        _segmentService.onGamePreferencesSet(selectedGames: top);
        _fbEventsService.onGamePreferencesSet(selectedGames: top);
        _sentPreferences = true;
      }

      // tiny prefetch of next page thumbnails
      _prefetchNextThumbnails();

      _hasMore = resp.hasMore;
      if (deduped.isEmpty) {
        AppLogger.w('[GamesByDevelopers] No games available on initial load.');
      }
    } catch (e, st) {
      AppLogger.e(
        '[GamesByDevelopers] Initial load failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final resp = await _service.fetchGames(page: nextPage);
      final add = resp.items.where((g) => _seen.add(g.id)).toList();
      if (add.isNotEmpty) {
        games.addAll(add);
        _page = nextPage;
        _prefetchNextThumbnails();
      }
      _hasMore = resp.hasMore;
      AppLogger.i(
        '[GamesByDevelopers] Load more page=$nextPage added=${add.length} hasMore=$_hasMore',
      );
    } catch (e, st) {
      AppLogger.e(
        '[GamesByDevelopers] Load more failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _prefetchNextThumbnails() {
    final ctx = Get.context;
    if (ctx == null) return;
    // Prefetch a couple of next images to avoid popping
    final start = games.length >= 3 ? games.length - 3 : 0;
    for (var i = start; i < games.length; i++) {
      final url = games[i].backgroundImage;
      if (url.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(url), ctx);
    }
  }

  @override
  void onClose() {
    _service.dispose();
    super.onClose();
  }

  bool get hasMore => _hasMore;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// UI
/// ─────────────────────────────────────────────────────────────────────────────

class GamesSection extends StatefulWidget {
  const GamesSection({super.key});

  @override
  State<GamesSection> createState() => _GamesSectionState();
}

class _GamesSectionState extends State<GamesSection> {
  final ctrl = Get.put(GamesController(), permanent: true);
  final _scroll = ScrollController();

  static const _cardW = 115.0;
  static const _gap = 20.0;
  static const _listH = 190.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 3 * (_cardW + _gap)) {
      ctrl.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAMES BY DEVELOPERS',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (ctrl.isLoading.value && ctrl.games.isEmpty) {
            return const Center(child: RainbowGlowingLoader(size: 40));
          }
          if (ctrl.games.isEmpty) {
            return Center(
              child: Text(
                'No games found',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            );
          }

          return SizedBox(
            height: _listH,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              physics: const BouncingScrollPhysics(),
              itemCount: ctrl.hasMore
                  ? ctrl.games.length +
                        1 // trailing loader cell
                  : ctrl.games.length,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                if (i >= ctrl.games.length) {
                  // loader cell
                  return const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(child: RainbowLoadingBar()),
                  );
                }
                final g = ctrl.games[i];
                final bg = ctrl.colorForGame(g);
                return RepaintBoundary(
                  child: GameCard(game: g, backgroundColor: bg),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;
  final Color backgroundColor;

  const GameCard({
    super.key,
    required this.game,
    required this.backgroundColor,
  });
  Widget hqCachedImage({
    required BuildContext context,
    required String url,
    required double renderWidth, // logical px of the widget
    required double renderHeight, // logical px of the widget
    BoxFit fit = BoxFit.cover,
    BorderRadius? radius,
    Widget? placeholder,
    Widget? error,
  }) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // Request decode close to actual physical pixels for crispness without waste
    final targetW = (renderWidth * dpr).round();
    final targetH = (renderHeight * dpr).round();

    final img = CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: targetW,
      memCacheHeight: targetH,
      imageBuilder: (ctx, provider) => Image(
        image: provider,
        fit: fit,
        filterQuality: FilterQuality.high, // <— sharper scaling
      ),
      fit: fit, // also used if imageBuilder not invoked yet
      placeholder: (_, __) =>
          placeholder ?? Container(color: const Color(0xFF1A1A1A)),
      errorWidget: (_, __, ___) =>
          error ?? const Icon(Icons.image_not_supported, color: Colors.white54),
    );

    if (radius == null) return img;
    return ClipRRect(borderRadius: radius, child: img);
  }

  @override
  Widget build(BuildContext context) {
    final segment = locator<SegmentSdkService>();
    final fb = locator<FbEventsService>();

    return BounceTap(
      onTap: () {
        segment.onGameDetailsViewed(
          gameId: game.id.toString(),
          cafeId: 'general',
        );
        fb.onGameDetailsViewed(gameId: game.id.toString(), cafeId: 'general');

        Get.snackbar(
          'Game Details',
          'Viewing details for ${game.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1B5E20),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      },
      child: Container(
        height: 150,
        width: 115,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Cover
            // inside GameCard.build
            Positioned.fill(
              child: game.backgroundImage.isEmpty
                  ? Container(color: const Color(0xFF1A1A1A))
                  : hqCachedImage(
                      context: context,
                      url: game.backgroundImage,
                      renderWidth: 115, // widget logical width
                      renderHeight: 150, // widget logical height
                      fit: BoxFit.cover,
                    ),
            ),

            // Frosted footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                  bottom: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          game.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.released,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (_) => const Icon(
                              Icons.star,
                              color: Color(0xFFE6D009),
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
