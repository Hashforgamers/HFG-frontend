import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';
import 'flappy_birds/Layouts/Pages/page_game.dart';
import 'flappy_birds/Layouts/Pages/page_start_screen.dart';
import 'ludo/ludo_game_screen.dart';
import 'mini_game_card.dart';
import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'models/minigame_model.dart';

class MiniGamesSection extends StatelessWidget {
  const MiniGamesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      MiniGame(
        title: "Fruit Cutting",
        subtitle: "Slice & earn coins",
        imageUrl:
        "assets/mini_game_icons/fruit_cutting.png",
        onTap: () => Get.to(() => FruitCuttingScreen()),
      ),
      MiniGame(
        title: "Plant vs Zombie",
        subtitle: "Test gaming knowledge",
        imageUrl:
        "assets/mini_game_icons/pvz.png",
        onTap: () => Get.to(PlantVsZombie()),
      ),
      MiniGame(
        title: "Pac Man",
        subtitle: "Daily rewards",
        imageUrl:
        "assets/mini_game_icons/pacman.png",
        onTap: () => Get.to(PacManHome()),
      ),MiniGame(
        title: "Laggy Bird",
        subtitle: "Daily rewards",
        imageUrl:
        "assets/mini_game_icons/flappy_birds.png",
        onTap: () => Get.to(GamePage()),
      ),MiniGame(
        title: "Ludo",
        subtitle: "Daily rewards",
        imageUrl:
        "assets/mini_game_icons/ludo_icon.png",
        onTap: () =>Get.to(() => const LudoGameScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          child: Text(
            "Mini Games 🎮",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) => MiniGameCard(game: games[index]),
          ),
        ),
      ],
    );
  }
}
