/*
 * @ Author: Flutter Journey 🎯 <flutterjourney.org@gmail.com>
 * @ Created: 2024-12-09 13:15:47
 * @ Message: You look very hardworking 👨‍💻. Keep focusing on your goals. 🌤️
 */

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/theme/app_colors.dart';
import 'dart:math';

// Defines a component for the fruit slicing effect, using particles to create the visual effect.
final Random _random = Random();
const List<Color> _colors = [
  AppColors.darkOrange,
  Colors.red,
  Colors.yellow,
  Color(0xff00DC00),
  Colors.blue,
];

class FruitSliceComponent extends ParticleSystemComponent {
  // Constructor that initializes the particle system with the given position
  FruitSliceComponent(Vector2 position)
    : super(
        // Generates a particle effect
        particle: Particle.generate(
          count: 10,
          lifespan: 0.5, // Duration each particle stays visible on the screen
          // Defines how each particle is generated
          generator: (i) {
            // Creates an individual particle with acceleration and speed
            return AcceleratedParticle(
              acceleration: Vector2(
                (_random.nextDouble() - 0.5) *
                    25, // Random acceleration on the x-axis
                (_random.nextDouble() - 0.5) *
                    25, // Random acceleration on the y-axis
              ),
              speed: Vector2(
                (_random.nextDouble() - 0.5) *
                    50, // Random initial speed on the x-axis
                (_random.nextDouble() - 0.5) *
                    50, // Random initial speed on the y-axis
              ),
              position: position, // Initial position of the particle
              child: CircleParticle(
                radius:
                    1 +
                    _random.nextDouble() * 2, // Random radius between 1 and 3
                paint: Paint()
                  ..color =
                      _colors[_random.nextInt(
                        _colors.length,
                      )], // Random color from the list
              ),
            );
          },
        ),
      );
}
