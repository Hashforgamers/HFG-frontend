import 'package:flutter/material.dart';
import 'Screens/game_over.dart';
import 'Screens/home_page.dart';

class Routes {
  Routes._();

  static const String game_over = '/game-over';
  static const String home = '/home';

  static final routes = <String, WidgetBuilder>{
    home: (BuildContext context) => PlantVsZombie(),
    game_over: (BuildContext context) => GameOver(),
  };
}
