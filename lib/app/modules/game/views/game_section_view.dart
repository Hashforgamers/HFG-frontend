// Optimized and polished GamesSection with efficient state handling and UI cleanup
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
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
    const Color(0xff0e213f)
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
      segmentService.onGameStarted(gameId: 'COD', mode: '123', entryFee: 123);
      games.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch games',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }
}

class GamesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GAMES BY DEVELOPERS',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GetX<GamesController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: RainbowGlowingLoader(size: 50));
            }
            if (controller.games.isEmpty) {
              return const Center(
                  child: Text('No games found',
                      style: TextStyle(color: Colors.white)));
            }
            return SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.games.length,
                itemBuilder: (context, index) =>
                    GameCard(game: controller.games[index]),
                separatorBuilder: (_, __) => SizedBox(width: 8),
              ),
            );
          },
        )
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: game.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8), topLeft: Radius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: game.backgroundImage,
              height: 100,
              width: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: RainbowGlowingLoader(size: 30)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Text(game.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(game.released,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('✪ ${game.rating}',
                    style: const TextStyle(color: Colors.amberAccent),
                    maxLines: 1),
                const Text('View More',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
