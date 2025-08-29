import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'main_router_game.dart'; // from repo

class FruitCuttingScreen extends StatelessWidget {
  final MainRouterGame game = MainRouterGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GameWidget(
          game: game,
        ),
      ),
    );
  }
}
