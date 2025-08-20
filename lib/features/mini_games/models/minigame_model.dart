import 'dart:ui';

class MiniGame {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  MiniGame({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });
}
