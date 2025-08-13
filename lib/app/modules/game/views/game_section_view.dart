// Optimized and polished GamesSection with efficient state handling and UI cleanup
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:http/http.dart' as http;

import '../../../../utils/widgets/glow_neon_loader.dart';

class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final String released;
  final double rating;
  final Color backgroundColor;

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.released,
    required this.rating,
    required this.backgroundColor,
  });

  factory Game.fromJson(Map<String, dynamic> json, List<Color> colors) {
    final random = Random();
    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      released: json['released'] ?? 'N/A',
      rating: (json['rating'] ?? 0.0).toDouble(),
      backgroundColor: colors[random.nextInt(colors.length)],
    );
  }
}

class GameService {
  static const String _apiKey = '5161e75d1d234431ac34d3947d01ea1e';
  static const String _baseUrl = 'https://api.rawg.io/api';

  Future<List<Game>> fetchGames(List<Color> colors) async {
    final url = Uri.parse('$_baseUrl/games?key=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['results'] as List;
      return data.map((game) => Game.fromJson(game, colors)).toList();
    } else {
      throw Exception('Failed to fetch games');
    }
  }
}

class GamesController extends GetxController {
  final games = <Game>[].obs;
  final isLoading = false.obs;
  final _service = GameService();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  final List<Color> _colors = [
    Colors.red[900]!,
    Colors.blue[900]!,
    Colors.green[900]!,
    Colors.purple[900]!,
    Colors.orange[900]!,
    Colors.cyan[900]!,
    Colors.amber[900]!,
    const Color(0xff37ebf3),
    const Color(0xffcb1dcd),
    const Color(0xff710000),
    const Color(0xff0e213f),
  ];

  @override
  void onInit() {
    super.onInit();
    if (games.isEmpty) fetchGames();
  }

  void fetchGames() async {
    if (isLoading.value || games.isNotEmpty) return;
    try {
      isLoading(true);
      final result = await _service.fetchGames(_colors);

      // Track game preferences set event when games are loaded
      final selectedGames = result.take(5).map((game) => game.name).toList();
      segmentService.onGamePreferencesSet(selectedGames: selectedGames);
      fbEventsService.onGamePreferencesSet(selectedGames: selectedGames);

      segmentService.onGameStarted(
        gameId: result[0].id.toString(),
        mode: 'paid',
        entryFee: 123,
      );
      fbEventsService.onGameStarted(
        gameId: result[0].id.toString(),
        mode: 'paid',
        entryFee: 123,
      );
      games.assignAll(result);
    } catch (e) {
      // Track game abandoned event on error
      segmentService.onGameAbandoned(
        gameId: 'general',
        reason: 'Failed to fetch games: $e',
      );
      fbEventsService.onGameAbandoned(
        gameId: 'general',
        reason: 'Failed to fetch games: $e',
      );

      Get.snackbar(
        'Error',
        'Failed to fetch games',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Method to track game completion
  void onGameCompleted(
    String gameId,
    String result,
    String duration,
    int pointsEarned,
  ) {
    segmentService.onGameCompleted(
      gameId: gameId,
      result: result,
      duration: duration,
      pointsEarned: pointsEarned,
    );
    fbEventsService.onGameCompleted(
      gameId: gameId,
      result: result,
      duration: duration,
      pointsEarned: pointsEarned,
    );
  }

  // Method to track game abandonment
  void onGameAbandoned(String gameId, String reason) {
    segmentService.onGameAbandoned(gameId: gameId, reason: reason);
    fbEventsService.onGameAbandoned(gameId: gameId, reason: reason);
  }
}

class GamesSection extends StatelessWidget {
  const GamesSection({super.key});

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
        GetX<GamesController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: RainbowGlowingLoader(size: 50));
            }
            if (controller.games.isEmpty) {
              return Center(
                child: Text(
                  'No games found',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              );
            }
            return SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.games.length,
                itemBuilder: (context, index) =>
                    GameCard(game: controller.games[index]),
                separatorBuilder: (_, __) => SizedBox(width: 20),
              ),
            );
          },
        ),
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final segmentService = locator<SegmentSdkService>();
    final fbEventsService = locator<FbEventsService>();

    return GestureDetector(
      onTap: () {
        // Track game details viewed event
        segmentService.onGameDetailsViewed(
          gameId: game.id.toString(),
          cafeId:
              'general', // Since this is a general game view, not cafe-specific
        );
        fbEventsService.onGameDetailsViewed(
          gameId: game.id.toString(),
          cafeId:
              'general', // Since this is a general game view, not cafe-specific
        );

        // Navigate to game details or show more info
        Get.snackbar(
          'Game Details',
          'Viewing details for ${game.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
      child: Container(
        height: 150,
        width: 115,
        decoration: BoxDecoration(
          color: game.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: game.backgroundImage,
                height: 150,
                width: 115,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
            ),
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
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          game.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.released,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (index) => const Icon(
                              Icons.star,
                              color: Color(0xFFE6D009),
                              size: 13,
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
