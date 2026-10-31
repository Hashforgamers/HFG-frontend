import 'package:flutter/material.dart';

/// Power Ludo power-ups. Everyone starts with one of each; a capture
/// refills a used one.
enum PowerUp {
  reroll(
    'Reroll',
    'Throw that roll again',
    Icons.refresh_rounded,
    Color(0xFF7D7AFF),
  ),
  luckySix(
    'Lucky Six',
    'Your next roll is a 6',
    Icons.casino_rounded,
    Color(0xFFFFC21A),
  ),
  boost(
    'Boost',
    '+3 squares on your next move',
    Icons.bolt_rounded,
    Color(0xFF30D158),
  ),
  shield(
    'Shield',
    'Pawns on the board can\'t be captured for 2 turns',
    Icons.shield_rounded,
    Color(0xFF3BC8FF),
  );

  const PowerUp(this.title, this.detail, this.icon, this.color);

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

/// Something that happened with a power-up, for the on-screen banner.
class PowerEvent {
  const PowerEvent({
    required this.id,
    required this.seat,
    required this.power,
    required this.gained,
  });

  final int id;
  final Object seat; // LudoPlayerType
  final PowerUp power;

  /// true = picked up, false = used.
  final bool gained;
}
