import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

/// Chunky player token in a seat colour: dark outline, glossy colour ring and
/// an avatar (photo or initial). Empty seats render as a sunken socket.
///
/// [progress] draws a countdown ring around the token (0–1) for the active turn.
class LudoSeatToken extends StatelessWidget {
  const LudoSeatToken({
    super.key,
    required this.color,
    this.name,
    this.photo,
    this.icon,
    this.size = 50,
    this.joinable = false,
    this.glow = false,
    this.progress,
    this.progressColor,
  });

  final Color color;

  /// Null means an empty seat.
  final String? name;
  final String? photo;

  /// Shown instead of an initial (e.g. an AI robot).
  final IconData? icon;
  final double size;
  final bool joinable;
  final bool glow;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final filled = name != null || icon != null;
    final token = filled ? _filled() : _empty();
    if (progress == null) return token;
    final ring = size + 12;
    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: ring,
            height: ring,
            child: CircularProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(progressColor ?? color),
              backgroundColor: GameColors.outline.withValues(alpha: 0.6),
            ),
          ),
          token,
        ],
      ),
    );
  }

  Widget _filled() {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final fallback = icon != null
        ? GameIcon(icon: icon!, size: size * 0.45)
        : GameText(initial, size: size * 0.36);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: GameColors.outline,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 14)]
            : null,
      ),
      child: Container(
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          ),
        ),
        child: ClipOval(
          child: Container(
            color: Color.lerp(color, Colors.black, 0.35),
            alignment: Alignment.center,
            child: photo != null && photo!.isNotEmpty
                ? Image.network(
                    photo!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
        ),
      ),
    );
  }

  Widget _empty() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GameColors.socket,
      border: Border.all(
        color: joinable
            ? color.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.08),
        width: 2,
      ),
    ),
    child: joinable
        ? Icon(Icons.add_rounded, size: size * 0.48, color: color)
        : null,
  );
}
