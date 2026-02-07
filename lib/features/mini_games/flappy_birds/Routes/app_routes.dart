// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_game.dart';
import '../Layouts/Pages/page_rate_us.dart';
import '../Layouts/Pages/page_settings.dart';
import '../Layouts/Pages/page_start_screen.dart';
import '../Resources/strings.dart';

class AppRoute {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Str.home:
        return MaterialPageRoute(builder: (_) => FlappyBirds());
      case Str.gamePage:
        return MaterialPageRoute(builder: (_) => GamePage());
      case Str.rateUs:
        return MaterialPageRoute(builder: (_) => RateUs());
      case Str.settings:
        return MaterialPageRoute(builder: (_) => Settings());
      default:
        _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Error Page"),
            backgroundColor: Colors.redAccent,
          ),
          body: Center(child: Text("Error")),
        );
      },
    );
  }
}
