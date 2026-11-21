import 'package:flutter/painting.dart';

/// 5×7 bitmap font for the low-resolution game frame. Glyphs are filled
/// pixel-by-pixel so text stays crisp when the frame is scaled up.
class RrFont {
  RrFont._();

  static const _glyphs = <String, String>{
    'A': '.###. #...# #...# ##### #...# #...# #...#',
    'B': '####. #...# #...# ####. #...# #...# ####.',
    'C': '.###. #...# #.... #.... #.... #...# .###.',
    'D': '####. #...# #...# #...# #...# #...# ####.',
    'E': '##### #.... #.... ####. #.... #.... #####',
    'F': '##### #.... #.... ####. #.... #.... #....',
    'G': '.###. #...# #.... #.### #...# #...# .###.',
    'H': '#...# #...# #...# ##### #...# #...# #...#',
    'I': '.###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.',
    'J': '..### ...#. ...#. ...#. ...#. #..#. .##..',
    'K': '#...# #..#. #.#.. ##... #.#.. #..#. #...#',
    'L': '#.... #.... #.... #.... #.... #.... #####',
    'M': '#...# ##.## #.#.# #.#.# #...# #...# #...#',
    'N': '#...# ##..# #.#.# #..## #...# #...# #...#',
    'O': '.###. #...# #...# #...# #...# #...# .###.',
    'P': '####. #...# #...# ####. #.... #.... #....',
    'Q': '.###. #...# #...# #...# #.#.# #..#. .##.#',
    'R': '####. #...# #...# ####. #.#.. #..#. #...#',
    'S': '.#### #.... #.... .###. ....# ....# ####.',
    'T': '##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..',
    'U': '#...# #...# #...# #...# #...# #...# .###.',
    'V': '#...# #...# #...# #...# #...# .#.#. ..#..',
    'W': '#...# #...# #...# #.#.# #.#.# ##.## #...#',
    'X': '#...# #...# .#.#. ..#.. .#.#. #...# #...#',
    'Y': '#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..',
    'Z': '##### ....# ...#. ..#.. .#... #.... #####',
    '0': '.###. #...# #..## #.#.# ##..# #...# .###.',
    '1': '..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.',
    '2': '.###. #...# ....# ...#. ..#.. .#... #####',
    '3': '####. ....# ....# .###. ....# ....# ####.',
    '4': '...#. ..##. .#.#. #..#. ##### ...#. ...#.',
    '5': '##### #.... ####. ....# ....# #...# .###.',
    '6': '.###. #.... #.... ####. #...# #...# .###.',
    '7': '##### ....# ...#. ..#.. .#... .#... .#...',
    '8': '.###. #...# #...# .###. #...# #...# .###.',
    '9': '.###. #...# #...# .#### ....# ....# .###.',
    '.': '..... ..... ..... ..... ..... .##.. .##..',
    ',': '..... ..... ..... ..... .##.. ..#.. .#...',
    ':': '..... .##.. .##.. ..... .##.. .##.. .....',
    '!': '..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..',
    '?': '.###. #...# ....# ...#. ..#.. ..... ..#..',
    '-': '..... ..... ..... .###. ..... ..... .....',
    '+': '..... ..#.. ..#.. ##### ..#.. ..#.. .....',
    '/': '....# ...#. ...#. ..#.. .#... .#... #....',
    '\$': '..#.. .#### #.#.. .###. ..#.# ####. ..#..',
    "'": '..#.. ..#.. .#... ..... ..... ..... .....',
    '>': '#.... .#... ..#.. ...#. ..#.. .#... #....',
    '<': '....# ...#. ..#.. .#... ..#.. ...#. ....#',
    '*': '..... #.#.# .###. ##### .###. #.#.# .....',
    '=': '..... ..... ##### ..... ##### ..... .....',
  };

  static final Map<int, Path> _paths = {
    for (final e in _glyphs.entries) e.key.codeUnitAt(0): _build(e.value),
  };

  static Path _build(String rows) {
    final path = Path();
    final lines = rows.split(' ');
    for (var y = 0; y < lines.length; y++) {
      for (var x = 0; x < 5; x++) {
        if (lines[y][x] == '#') {
          path.addRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1));
        }
      }
    }
    return path;
  }

  static final Paint _paint = Paint()..isAntiAlias = false;

  static int width(String text, {int scale = 1}) =>
      text.isEmpty ? 0 : (text.length * 6 - 1) * scale;

  static void draw(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color, {
    int scale = 1,
    Color? shadow,
  }) {
    if (shadow != null) {
      draw(canvas, text, x + scale, y + scale, shadow, scale: scale);
    }
    _paint.color = color;
    final upper = text.toUpperCase();
    for (var i = 0; i < upper.length; i++) {
      final path = _paths[upper.codeUnitAt(i)];
      if (path == null) continue;
      canvas.save();
      canvas.translate(x + i * 6.0 * scale, y);
      canvas.scale(scale.toDouble());
      canvas.drawPath(path, _paint);
      canvas.restore();
    }
  }

  static void center(
    Canvas canvas,
    String text,
    double cx,
    double y,
    Color color, {
    int scale = 1,
    Color? shadow,
  }) => draw(
    canvas,
    text,
    (cx - width(text, scale: scale) / 2).roundToDouble(),
    y,
    color,
    scale: scale,
    shadow: shadow,
  );

  static void right(
    Canvas canvas,
    String text,
    double rightX,
    double y,
    Color color, {
    int scale = 1,
  }) => draw(
    canvas,
    text,
    rightX - width(text, scale: scale),
    y,
    color,
    scale: scale,
  );
}
