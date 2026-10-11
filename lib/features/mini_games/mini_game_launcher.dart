import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hash/features/mini_games/arrow_escape/arrow_escape_screen.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_start_screen.dart';
import 'package:hash/features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';
import 'package:hash/features/mini_games/html_games/views/html_game_player_screen.dart';
import 'package:hash/features/mini_games/ludo/ludo_game_screen.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';
import 'package:hash/features/mini_games/road_rumble/road_rumble_screen.dart';
import 'package:hash/features/mini_games/snakes_ladders/snl_game_screen.dart';
import 'package:hash/features/mini_games/wordly/wordly_screen.dart';

/// An arcade game that can be opened by id from anywhere in the app.
class ArcadeGameEntry {
  const ArcadeGameEntry({
    required this.id,
    required this.title,
    required this.icon,
    required this.open,
  });

  final String id;
  final String title;
  final String icon;
  final Future<void> Function() open;
}

/// Opens arcade games by id (native and HTML), for entry points outside the
/// Hash Arcade row.
abstract final class MiniGameLauncher {
  static const defaultGameId = 'ludo';

  static final Map<String, ArcadeGameEntry> _native = {
    for (final e in <ArcadeGameEntry>[
      ArcadeGameEntry(
        id: 'ludo',
        title: 'Ludo',
        icon: 'assets/mini_game_icons/ludo_icon.png',
        open: () async => Get.to(() => const LudoGameScreen(source: 'home')),
      ),
      ArcadeGameEntry(
        id: 'snakes_ladders',
        title: 'Snakes & Ladders',
        icon: 'assets/mini_game_icons/snakes_ladders.png',
        open: () async => Get.to(() => const SnlGameScreen()),
      ),
      ArcadeGameEntry(
        id: 'road_rumble',
        title: 'Road Rumble',
        icon: 'assets/mini_game_icons/road_rumble.png',
        open: () async => Get.to(() => const RoadRumbleScreen()),
      ),
      ArcadeGameEntry(
        id: 'arrow_escape',
        title: 'Arrow Escape',
        icon: 'assets/mini_game_icons/arrow_escape.png',
        open: () async => Get.to(() => const ArrowEscapeScreen()),
      ),
      ArcadeGameEntry(
        id: 'fruit_cutting',
        title: 'Fruit Cutting',
        icon: 'assets/mini_game_icons/fruit_cutting.png',
        open: () async => Get.to(() => const FruitCuttingScreen()),
      ),
      ArcadeGameEntry(
        id: 'plant_vs_zombie',
        title: 'Plant vs Zombie',
        icon: 'assets/mini_game_icons/pvz.png',
        open: () async => Get.to(() => const PlantVsZombie()),
      ),
      ArcadeGameEntry(
        id: 'pac_man',
        title: 'Pac Man',
        icon: 'assets/mini_game_icons/pacman.png',
        open: () async => Get.to(() => const PacManHome()),
      ),
      ArcadeGameEntry(
        id: 'wordly',
        title: 'Wordly',
        icon: 'assets/mini_game_icons/wordly.png',
        open: () async => Get.to(() => const WordlyGame()),
      ),
      ArcadeGameEntry(
        id: 'laggy_bird',
        title: 'Laggy Bird',
        icon: 'assets/mini_game_icons/flappy_birds.png',
        open: () async => Get.to(() => const FlappyBirds()),
      ),
    ])
      e.id: e,
  };

  /// The entry for [gameId], or null if no such game is in the arcade.
  static ArcadeGameEntry? find(String? gameId) {
    if (gameId == null) return null;
    final native = _native[gameId];
    if (native != null) return native;
    for (final game in HtmlMiniGameCatalogService.games) {
      if (game.gameId == gameId) {
        return ArcadeGameEntry(
          id: game.gameId,
          title: game.name,
          icon: game.thumbnail,
          open: () => HtmlGamePlayerScreen.open(game, source: 'home'),
        );
      }
    }
    return null;
  }

  /// [gameId] if it exists, otherwise the default game.
  static ArcadeGameEntry resolve(String? gameId) =>
      find(gameId) ?? _native[defaultGameId]!;

  @visibleForTesting
  static Iterable<String> get nativeIds => _native.keys;
}
