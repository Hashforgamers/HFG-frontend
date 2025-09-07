import 'package:flutter/material.dart';

class MyGhost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: Image.asset('lib/features/mini_games/pacman/images/ghost.png'),
    );
  }
}
