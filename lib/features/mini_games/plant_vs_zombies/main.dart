import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/routes.dart';

import 'Screens/home_page.dart';

void main() {
  runApp(MyApp());
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plants vs Zombie',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PlantVsZombie(),
      routes: Routes.routes,
    );
  }
}
