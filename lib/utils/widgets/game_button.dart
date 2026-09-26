import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour sets for [GameButton].
enum GameButtonTone { green, red, yellow, purple, grey }

class _Palette {
  const _Palette(this.top, this.bottom, this.lip, this.subtitle);

  final Color top;
  final Color bottom;
  final Color lip;
  final Color subtitle;
}

const _palettes = {
  GameButtonTone.green: _Palette(
    Color(0xFF7CF06B),
    Color(0xFF2FBF3A),
    Color(0xFF1B7F24),
    Color(0xFF0E4A14),
  ),
  GameButtonTone.red: _Palette(
    Color(0xFFFF7A6B),
    Color(0xFFE8392C),
    Color(0xFF9E1E16),
    Color(0xFF5C0F0A),
  ),
  GameButtonTone.yellow: _Palette(
    Color(0xFFFFE45C),
    Color(0xFFFFC21A),
    Color(0xFFD08A00),
    Color(0xFF8A4B00),
  ),
  GameButtonTone.purple: _Palette(
    Color(0xFF8F7BFF),
    Color(0xFF6A4DF0),
    Color(0xFF4127B0),
    Color(0xFF26157A),
  ),
  GameButtonTone.grey: _Palette(
    Color(0xFF5A5A60),
    Color(0xFF3F3F44),
    Color(0xFF26262A),
    Color(0xFFB0B0B8),
  ),
};

/// Chunky, tactile "mobile game" button: thick dark outline, a 3D bottom lip,
/// a glossy top highlight and bold outlined text. The face drops onto the lip
/// while pressed.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = GameButtonTone.green,
    this.icon,
    this.subtitle,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonTone tone;
  final IconData? icon;

  /// Optional small second line under the label, e.g. "2 seats left".
  final String? subtitle;
  final double height;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  static const _outline = Color(0xFF0B0B10);
  static const _lipDepth = 5.0;
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = _palettes[_enabled ? widget.tone : GameButtonTone.grey]!;
    final radius = BorderRadius.circular(widget.height * 0.34);
    final drop = _down ? _lipDepth - 1 : 0.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height + _lipDepth + 6,
          child: Stack(
            children: [
              // Outline + 3D lip.
              Positioned.fill(
                top: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _outline,
                    borderRadius: BorderRadius.circular(
                      widget.height * 0.34 + 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.lip,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              // Face.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 3,
                right: 3,
                top: 3 + drop,
                height: widget.height - 3,
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [p.top, p.bottom],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Gloss band.
                        Positioned(
                          left: 8,
                          right: 8,
                          top: 4,
                          height: (widget.height - 3) * 0.36,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                widget.height,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(child: _content(p)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(_Palette p) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          GameIcon(icon: widget.icon!, size: widget.height * 0.4),
          const SizedBox(width: 8),
        ],
        GameText(
          widget.label,
          size: widget.subtitle == null
              ? widget.height * 0.38
              : widget.height * 0.34,
        ),
      ],
    );
    if (widget.subtitle == null) return title;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        Text(
          widget.subtitle!,
          style: GoogleFonts.lilitaOne(
            color: p.subtitle,
            fontSize: widget.height * 0.2,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// White chunky text with a dark stroke and a hard drop shadow.
class GameText extends StatelessWidget {
  const GameText(
    this.text, {
    super.key,
    required this.size,
    this.color = Colors.white,
  });

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.lilitaOne(fontSize: size, height: 1.05);
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(0, size * 0.09),
          child: Text(
            text,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.2
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF0B0B10),
            ),
          ),
        ),
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF0B0B10),
          ),
        ),
        Text(text, style: base.copyWith(color: color)),
      ],
    );
  }
}

/// White icon with a dark outline and drop shadow, to sit next to [GameText].
class GameIcon extends StatelessWidget {
  const GameIcon({super.key, required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(0, size * 0.08),
          child: Icon(
            icon,
            size: size,
            color: const Color(0xFF0B0B10),
            shadows: const [
              Shadow(color: Color(0xFF0B0B10), blurRadius: 0.5),
            ],
          ),
        ),
        Icon(
          icon,
          size: size,
          color: Colors.white,
          shadows: const [
            Shadow(color: Color(0xFF0B0B10), offset: Offset(1.2, 0)),
            Shadow(color: Color(0xFF0B0B10), offset: Offset(-1.2, 0)),
            Shadow(color: Color(0xFF0B0B10), offset: Offset(0, 1.2)),
            Shadow(color: Color(0xFF0B0B10), offset: Offset(0, -1.2)),
          ],
        ),
      ],
    );
  }
}
