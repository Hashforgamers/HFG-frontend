import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Model Class for Game
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

/// Service Class to Fetch Games
class GameService {
  static const String _apiKey = '5161e75d1d234431ac34d3947d01ea1e';
  static const String _baseUrl = 'https://api.rawg.io/api';

  Future<List<Game>> fetchGames(List<Color> colors) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/games?key=$_apiKey'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['results'];
        return data.map((game) => Game.fromJson(game, colors)).toList();
      } else {
        throw Exception('Failed to fetch games');
      }
    } catch (e) {
      throw Exception('Error fetching games: $e');
    }
  }
}

/// Controller for Managing Game Data
class GamesController extends GetxController {
  var games = <Game>[].obs;
  final isLoading = false.obs;
  final GameService _gameService = GameService();

  // Predefined colors to ensure consistent color assignment
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
    if (games.isEmpty) {
      fetchGames();
    }
  }

  void fetchGames() async {
    if (isLoading.value || games.isNotEmpty) return;
    try {
      isLoading(true);
      final fetchedGames = await _gameService.fetchGames(_colors);
      games.assignAll(fetchedGames);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch games: $e');
    } finally {
      isLoading(false);
    }
  }
}

/// Games Section Widget
class GamesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GAMES BY DEVELOPERS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GetBuilder<GamesController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (controller.games.isEmpty) {
              return const Center(
                child: Text(
                  'No games found',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.games
                      .map((game) => GameCard(game: game))
                      .toList(),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// Stateless Widget for Each Game Card
class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        color: game.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8), topLeft: Radius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: game.backgroundImage,
              height: 100,
              width: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    game.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    game.released,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '✪ ${game.rating}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'View More',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
