import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class GamesSection extends StatelessWidget {
  final GamesController _gamesController = Get.put(GamesController());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAMES BY DEVELOPERS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Obx(() {
          if (_gamesController.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else if (_gamesController.games.isEmpty) {
            return Center(child: Text('No games found'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _gamesController.games.map((game) => _buildGameItem(game)).toList(),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _buildGameItem(Game game) {
    final random = Random();
    final colors = [
      Colors.red[900],
      Colors.blue[900],
      Colors.green[900],
      Colors.purple[900],
      Colors.orange[900],
      Colors.cyan[900],
      Colors.amber[900],
      Color(0xff37ebf3),
      Color(0xffcb1dcd),
      Color(0xff710000),
      Color(0xff0e213f),
    ];
    final color = colors[random.nextInt(colors.length)];

    return Container(
      margin: EdgeInsets.all(5),
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(topRight: Radius.circular(8), topLeft: Radius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: game.backgroundImage,
              height: 100,
              width: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    game.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    game.released,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '✪ ${game.rating}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'View More',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class GameService {
  static const String _apiKey = '5161e75d1d234431ac34d3947d01ea1e'; // Replace with your RAWG API key
  static const String _baseUrl = 'https://api.rawg.io/api';

  Future<List<Game>> fetchGamesByDeveloper(String developer) async {
    final response = await http.get(Uri.parse('$_baseUrl/games?key=$_apiKey'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      return data.map((game) => Game.fromJson(game)).toList();
    } else {
      throw Exception('Failed to load games');
    }
  }
}

class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final String released;
  final double rating;

  Game({required this.id, required this.name, required this.backgroundImage, required this.released, required this.rating});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      released: json['released'] ?? '2024-05-28',
      rating: json['rating'] ?? 0.0,
    );
  }
}

class GamesController extends GetxController {
  var games = <Game>[].obs;
  var isLoading = true.obs;
  final GameService _gameService = GameService();

  @override
  void onInit() {
    fetchGames();
    super.onInit();
  }

  void fetchGames() async {
    try {
      isLoading(true);
      var fetchedGames = await _gameService.fetchGamesByDeveloper('developer_name'); // Replace 'developer_name' with the actual developer name
      if (fetchedGames != null) {
        games.value = fetchedGames;
      }
    } finally {
      isLoading(false);
    }
  }
}
