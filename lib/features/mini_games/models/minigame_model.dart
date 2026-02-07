import 'package:flutter/widgets.dart';

class MiniGame {
  final String? id;
  final String title;
  final String subtitle;
  final AssetImage icon;
  final VoidCallback onTap;

  MiniGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
