/*
 * @ Author: Flutter Journey 🎯 <flutterjourney.org@gmail.com>
 * @ Created: 2024-12-09 13:15:47
 * @ Message: You look very hardworking 👨‍💻. Keep focusing on your goals. 🌤️
 */

import 'package:flame/components.dart';

class AppConfig {
  static const gravity = -9.81;
  /// Fruit/bomb size in logical px (was 50; bumped for easier slicing).
  static const double objSize = 72;
  static const double acceleration = -400;
  // A fresh vector each time: a shared static Vector2 is mutable.
  static Vector2 get shapeSize => Vector2.all(objSize);
}
