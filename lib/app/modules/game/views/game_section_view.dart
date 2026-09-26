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
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/utils/widgets/home_section_title.dart';

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
        '[GamesByDevelopers] RAWG_API_KEY is not set; skipping fetch. Set AppKeys.rawgApiKey in lib/config/app_keys.dart.',
      );
      return (items: const <Game>[], hasMore: false);
    }

    final now = DateTime.now();
    final fromDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final future = DateTime(now.year + 2, now.month, now.day);
    final toDate =
        '${future.year.toString().padLeft(4, '0')}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '$_baseUrl/games?key=$_apiKey&page=$page&page_size=$pageSize&dates=$fromDate,$toDate&ordering=released',
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
  static const Duration _cacheTtl = Duration(minutes: 20);
  static List<Game>? _cachedGames;
  static DateTime? _cacheTime;
  static bool _cachedHasMore = true;
  static int _cachedPage = 1;

  final _service = GameService();

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

    final hasFreshCache =
        _cachedGames != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl;
    if (hasFreshCache) {
      games.assignAll(_cachedGames!);
      _page = _cachedPage;
      _hasMore = _cachedHasMore;
      _seen
        ..clear()
        ..addAll(games.map((game) => game.id));
      return;
    }

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

      // tiny prefetch of next page thumbnails
      _prefetchNextThumbnails();

      _hasMore = resp.hasMore;
      _saveCache();
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
      _saveCache();
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

  void _saveCache() {
    _cachedGames = games.toList(growable: false);
    _cacheTime = DateTime.now();
    _cachedHasMore = _hasMore;
    _cachedPage = _page;
  }
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

  static const _cardW = 132.0;
  static const _gap = 12.0;
  static const _listH = 212.0;

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
    return Obx(() {
      if (!ctrl.isLoading.value && ctrl.games.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle(title: 'Upcoming ', accent: 'Games'),
          const SizedBox(height: 12),
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
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
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
                      child: Center(child: AppLinearLoader()),
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
    });
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
        locator<AnalyticsService>().log(
          'game_selected',
          parameters: {
            'game_id': game.id.toString(),
            'game_name': game.name,
            'source_screen': 'games',
          },
        );
        locator<AnalyticsService>().setUserProperties(primaryGame: game.name);
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
      child: _AppleGameCard(
        game: game,
        backgroundColor: backgroundColor,
        cover: game.backgroundImage.isEmpty
            ? null
            : hqCachedImage(
                context: context,
                url: game.backgroundImage,
                renderWidth: 132,
                renderHeight: 200,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

/// Upcoming game card in an Apple poster style: cover with continuous
/// corners, a frosted release-date chip and a frosted name + rating bar.
class _AppleGameCard extends StatelessWidget {
  const _AppleGameCard({
    required this.game,
    required this.backgroundColor,
    required this.cover,
  });

  final Game game;
  final Color backgroundColor;
  final Widget? cover;

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// "2026-09-28" -> ("SEP", "28"); anything else is shown as-is.
  (String, String)? get _date {
    final d = DateTime.tryParse(game.released);
    if (d == null) return null;
    return (_months[d.month - 1], d.day.toString());
  }

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: -0.15,
        height: 1.2,
      );

  Widget _glass({required Widget child, BorderRadius? radius}) {
    final r = radius ?? BorderRadius.circular(999);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: r,
            border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return Container(
      width: 132,
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          side: BorderSide(color: Color(0x5900DC00), width: 0.8),
        ),
        color: Color.lerp(backgroundColor, const Color(0xFF1C1C1E), 0.6),
        shadows: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
          BoxShadow(color: Color(0x2E00DC00), blurRadius: 14, spreadRadius: -2),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          cover ??
              const Center(
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.white30,
                  size: 40,
                ),
              ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xB3000000),
                ],
                stops: [0, 0.25, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _glass(
              radius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: date == null
                    ? Text(
                        game.released,
                        style: _text(11, Colors.white, weight: FontWeight.w600),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            date.$1,
                            style: _text(
                              9.5,
                              const Color(0xFFFF453A),
                              weight: FontWeight.w700,
                            ).copyWith(letterSpacing: 0.5),
                          ),
                          Text(
                            date.$2,
                            style: _text(
                              17,
                              Colors.white,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1.05),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.5),
                    border: const Border(
                      top: BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(14, Colors.white, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          4,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 1),
                            child: Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFD60A),
                              size: 13,
                            ),
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
    );
  }
}
