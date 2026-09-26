import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/game_button.dart';

/// Shared "chunky mobile game" surfaces that pair with [GameButton]: thick dark
/// outlines, a 3D bottom lip, glossy headers and recessed trays.
class GameColors {
  static const outline = Color(0xFF0B0B10);
  static const bodyTop = Color(0xFF4B36B8);
  static const bodyBottom = Color(0xFF33238A);
  static const lip = Color(0xFF1E145C);
  static const tray = Color(0xFF1B1250);
  static const trayEdge = Color(0xFF120B38);
  static const socket = Color(0xFF110A33);
  static const soft = Color(0xFFC9C0FF);
  static const bgTop = Color(0xFF2A1C78);
  static const bgBottom = Color(0xFF140C3F);

  static const green = (Color(0xFF7CF06B), Color(0xFF2FBF3A));
  static const red = (Color(0xFFFF7A6B), Color(0xFFE8392C));
  static const yellow = (Color(0xFFFFE45C), Color(0xFFFFB81A));
  static const purple = (Color(0xFF8F7BFF), Color(0xFF6A4DF0));
  static const grey = (Color(0xFF6E6E78), Color(0xFF4A4A52));
}

/// Chunky text style for body copy on game surfaces.
TextStyle gameFont(double size, Color color) =>
    GoogleFonts.lilitaOne(color: color, fontSize: size, height: 1.15);

/// Outline → lip → body panel with an optional glossy header band.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.header,
    this.headerColors = GameColors.green,
    this.headerHeight = 60,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  final Widget child;

  /// Content for the header band; omit for a plain panel.
  final Widget? header;
  final (Color, Color) headerColors;
  final double headerHeight;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      decoration: BoxDecoration(
        color: GameColors.outline,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: GameColors.lip,
          borderRadius: BorderRadius.circular(21),
        ),
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.bodyTop, GameColors.bodyBottom],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null)
                  GameHeaderBand(
                    colors: headerColors,
                    height: headerHeight,
                    child: header!,
                  ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

/// Glossy coloured band with a faint dice pattern, used as a panel header.
class GameHeaderBand extends StatelessWidget {
  const GameHeaderBand({
    super.key,
    required this.colors,
    required this.child,
    this.height = 60,
  });

  final (Color, Color) colors;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        border: const Border(
          bottom: BorderSide(color: GameColors.outline, width: 3),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: GameIconPattern()),
          Positioned(
            left: 10,
            right: 10,
            top: 5,
            height: height * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fill the band and centre the content vertically; the 3px bottom
          // border is excluded so it reads centred on the colour.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recessed inset area inside a [GamePanel].
class GameTray extends StatelessWidget {
  const GameTray({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 12, 8, 10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.trayEdge, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.trayEdge, GameColors.tray, GameColors.tray],
          stops: [0, 0.18, 1],
        ),
      ),
      child: child,
    );
  }
}

/// Dark outlined pill for status labels (LIVE, OPEN, 2/4…).
class GameBadge extends StatelessWidget {
  const GameBadge({super.key, required this.label, this.dot, this.pulse});

  final String label;
  final Color? dot;

  /// Optional animation driving a pulse on the dot.
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    Widget? dotWidget;
    if (dot != null) {
      dotWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dot,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.2),
        ),
      );
      if (pulse != null) {
        dotWidget = ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.1).animate(pulse!),
          child: dotWidget,
        );
      }
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 5),
      decoration: BoxDecoration(
        color: GameColors.outline.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.outline, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotWidget != null) ...[dotWidget, const SizedBox(width: 5)],
          Text(label, style: gameFont(13, Colors.white)),
        ],
      ),
    );
  }
}

/// Square chunky icon button (back, restart, close) matching [GameButton].
class GameIconButton extends StatefulWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.colors = GameColors.purple,
    this.size = 44,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final (Color, Color) colors;
  final double size;
  final String? tooltip;

  @override
  State<GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<GameIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = widget.colors;
    final lip = Color.lerp(bottom, Colors.black, 0.4)!;
    const depth = 4.0;
    final button = GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.size,
        height: widget.size + depth,
        child: Container(
          decoration: BoxDecoration(
            color: GameColors.outline,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              color: lip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  left: 0,
                  right: 0,
                  top: _down ? depth - 1 : 0,
                  height: widget.size - 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [top, bottom],
                        ),
                      ),
                      child: Center(
                        child: GameIcon(
                          icon: widget.icon,
                          size: widget.size * 0.48,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}

/// Deep purple backdrop with a faint diamond grid, like a game menu floor.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.bgTop, GameColors.bgBottom],
          ),
        ),
        child: CustomPaint(painter: _DiamondGridPainter()),
      ),
    );
  }
}

class _DiamondGridPainter extends CustomPainter {
  const _DiamondGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiamondGridPainter oldDelegate) => false;
}

/// Faint tilted dice scattered across a header band.
class GameIconPattern extends StatelessWidget {
  const GameIconPattern({super.key, this.icon = Icons.casino_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const spots = [
      (0.18, 0.2, -0.3),
      (0.42, 0.75, 0.25),
      (0.62, 0.15, -0.15),
      (0.86, 0.7, 0.35),
      (0.02, 0.85, 0.2),
    ];
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            for (final (x, y, turn) in spots)
              Positioned(
                left: box.maxWidth * x,
                top: box.maxHeight * y - 14,
                child: Transform.rotate(
                  angle: turn,
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A confirm dialog drawn as a [GamePanel]. Returns true when confirmed.
Future<bool?> showGameDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  GameButtonTone confirmTone = GameButtonTone.green,
  (Color, Color) headerColors = GameColors.purple,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GamePanel(
        headerColors: headerColors,
        header: Center(child: GameText(title, size: 22)),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: gameFont(15, Colors.white),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: cancelLabel,
                    tone: GameButtonTone.purple,
                    height: 46,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: confirmLabel,
                    tone: confirmTone,
                    height: 46,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
