import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import 'cosmetics.dart';

// The themes each mini game sells. Every catalog starts with its free
// `<slot>_classic`, which matches how the game looked before themes existed.

// ----------------------------------------------------------- Arrow Escape

class ArrowLook {
  const ArrowLook({
    required this.palette,
    this.boardTop = const Color(0xFF231868),
    this.boardBottom = GameColors.tray,
    this.tile = const Color(0x0CFFFFFF),
    this.outline = GameColors.outline,
  });

  /// Arrow colours, cycled by arrow id.
  final List<Color> palette;
  final Color boardTop;
  final Color boardBottom;

  /// Checker squares on the board.
  final Color tile;
  final Color outline;

  static const slot = 'arrow_theme';

  static const all = <Cosmetic<ArrowLook>>[
    Cosmetic(
      id: 'arrow_theme_classic',
      name: 'Classic',
      tagline: 'The original rainbow.',
      price: 0,
      look: ArrowLook(
        palette: [
          Color(0xFFFF6B6B),
          Color(0xFFFFD93D),
          Color(0xFF6BCB77),
          Color(0xFF4D96FF),
          Color(0xFFFF9F45),
          Color(0xFFC77DFF),
          Color(0xFF4DD6D0),
          Color(0xFFFF7EB6),
        ],
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_ocean',
      name: 'Ocean',
      tagline: 'Cool blues and sea greens.',
      price: 500,
      look: ArrowLook(
        palette: [
          Color(0xFF4DABF7),
          Color(0xFF38D9A9),
          Color(0xFF74C0FC),
          Color(0xFF3BC9DB),
          Color(0xFF91A7FF),
          Color(0xFF63E6BE),
        ],
        boardTop: Color(0xFF0B3A5C),
        boardBottom: Color(0xFF06223A),
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_sunset',
      name: 'Sunset',
      tagline: 'Warm reds, oranges and gold.',
      price: 800,
      look: ArrowLook(
        palette: [
          Color(0xFFFF6B6B),
          Color(0xFFFF922B),
          Color(0xFFFFD43B),
          Color(0xFFF783AC),
          Color(0xFFFFA94D),
          Color(0xFFE64980),
        ],
        boardTop: Color(0xFF5C1A3A),
        boardBottom: Color(0xFF2B0B22),
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_pink',
      name: 'Pink Rush',
      tagline: 'Every shade of pink.',
      price: 1500,
      look: ArrowLook(
        palette: [
          Color(0xFFFF5FA2),
          Color(0xFFFFB3D1),
          Color(0xFFE64980),
          Color(0xFFFCC2D7),
          Color(0xFFF06595),
          Color(0xFFDA77F2),
        ],
        boardTop: Color(0xFF6B1746),
        boardBottom: Color(0xFF3A0B27),
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_mono',
      name: 'Chalk',
      tagline: 'White arrows on a blackboard.',
      price: 1500,
      look: ArrowLook(
        palette: [
          Color(0xFFFFFFFF),
          Color(0xFFDEE2E6),
          Color(0xFFADB5BD),
          Color(0xFFF1F3F5),
        ],
        boardTop: Color(0xFF2B2F36),
        boardBottom: Color(0xFF15171B),
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_neon',
      name: 'Neon',
      tagline: 'Electric colours on black.',
      price: 2500,
      look: ArrowLook(
        palette: [
          Color(0xFF39FF88),
          Color(0xFFFF2BD6),
          Color(0xFF00E5FF),
          Color(0xFFFFF000),
          Color(0xFFFF6B00),
          Color(0xFF9D4DFF),
        ],
        boardTop: Color(0xFF0A0A16),
        boardBottom: Color(0xFF000000),
        tile: Color(0x14FFFFFF),
      ),
    ),
    Cosmetic(
      id: 'arrow_theme_gold',
      name: 'Gold Vault',
      tagline: 'Solid gold on royal purple.',
      price: 4000,
      look: ArrowLook(
        palette: [
          Color(0xFFFFD700),
          Color(0xFFFFE680),
          Color(0xFFE0A800),
          Color(0xFFFFF3B0),
          Color(0xFFD4AF37),
        ],
        boardTop: Color(0xFF3A1470),
        boardBottom: Color(0xFF1A0838),
        outline: Color(0xFF3D2A00),
      ),
    ),
  ];

  static ArrowLook get current => CosmeticStore.instance.pick(slot, all).look;
}

// ----------------------------------------------------------------- Pac Man

class PacLook {
  const PacLook({
    this.background = const Color(0xFF05041A),
    this.wall = const Color(0xFF1B1766),
    this.wallLine = const Color(0xFF6E8BFF),
    this.dot = const Color(0xFFFFE0B0),
    this.pacLight = const Color(0xFFFFF27A),
    this.pacDark = const Color(0xFFFFC400),
  });

  final Color background;
  final Color wall;
  final Color wallLine;
  final Color dot;

  /// Pac-Man's body gradient.
  final Color pacLight;
  final Color pacDark;

  static const slot = 'pac_theme';

  static const all = <Cosmetic<PacLook>>[
    Cosmetic(
      id: 'pac_theme_classic',
      name: 'Classic',
      tagline: 'Arcade blue.',
      price: 0,
      look: PacLook(),
    ),
    Cosmetic(
      id: 'pac_theme_retro',
      name: 'Retro Green',
      tagline: 'An old phosphor monitor.',
      price: 500,
      look: PacLook(
        background: Color(0xFF02140A),
        wall: Color(0xFF0B3D1E),
        wallLine: Color(0xFF39FF88),
        dot: Color(0xFFD8FFE6),
      ),
    ),
    Cosmetic(
      id: 'pac_theme_pink',
      name: 'Hot Pink',
      tagline: 'A bubblegum maze and a pink Pac.',
      price: 800,
      look: PacLook(
        background: Color(0xFF1A0412),
        wall: Color(0xFF4A0E34),
        wallLine: Color(0xFFFF5FA2),
        dot: Color(0xFFFFE0F0),
        pacLight: Color(0xFFFFB3D1),
        pacDark: Color(0xFFFF4F9A),
      ),
    ),
    Cosmetic(
      id: 'pac_theme_ice',
      name: 'Ice Cave',
      tagline: 'Frozen walls, frosty Pac.',
      price: 1500,
      look: PacLook(
        background: Color(0xFF04121A),
        wall: Color(0xFF0E3A52),
        wallLine: Color(0xFF7DD3FC),
        dot: Colors.white,
        pacLight: Color(0xFFE6FBFF),
        pacDark: Color(0xFF7DD3FC),
      ),
    ),
    Cosmetic(
      id: 'pac_theme_lava',
      name: 'Lava',
      tagline: 'A maze of molten rock.',
      price: 2500,
      look: PacLook(
        background: Color(0xFF1A0500),
        wall: Color(0xFF4A1204),
        wallLine: Color(0xFFFF6B1A),
        dot: Color(0xFFFFD166),
        pacLight: Color(0xFFFFE27A),
        pacDark: Color(0xFFFF9F1C),
      ),
    ),
    Cosmetic(
      id: 'pac_theme_gold',
      name: 'Gold Rush',
      tagline: 'Gilded walls, platinum Pac.',
      price: 4000,
      look: PacLook(
        background: Color(0xFF140F02),
        wall: Color(0xFF3D2E05),
        wallLine: Color(0xFFFFD166),
        dot: Color(0xFFFFF3B0),
        pacLight: Colors.white,
        pacDark: Color(0xFFCED4DA),
      ),
    ),
  ];

  static PacLook get current => CosmeticStore.instance.pick(slot, all).look;
}

// ------------------------------------------------------------------ Wordly

class WordlyLook {
  const WordlyLook({
    this.correct = GameColors.green,
    this.present = GameColors.yellow,
    this.absent = GameColors.grey,
  });

  /// Tile gradients (top, bottom) for each letter mark.
  final (Color, Color) correct;
  final (Color, Color) present;
  final (Color, Color) absent;

  static const slot = 'wordly_theme';

  static const all = <Cosmetic<WordlyLook>>[
    Cosmetic(
      id: 'wordly_theme_classic',
      name: 'Classic',
      tagline: 'Green and yellow.',
      price: 0,
      look: WordlyLook(),
    ),
    Cosmetic(
      id: 'wordly_theme_contrast',
      name: 'High Contrast',
      tagline: 'Orange and blue, easy to tell apart.',
      price: 300,
      look: WordlyLook(
        correct: (Color(0xFFFFA94D), Color(0xFFE8590C)),
        present: (Color(0xFF74C0FC), Color(0xFF1C7ED6)),
      ),
    ),
    Cosmetic(
      id: 'wordly_theme_bubblegum',
      name: 'Bubblegum',
      tagline: 'Pink hits, lilac near-misses.',
      price: 600,
      look: WordlyLook(
        correct: (Color(0xFFFF9CC8), Color(0xFFFF4F9A)),
        present: (Color(0xFFD0BFFF), Color(0xFF9775FA)),
      ),
    ),
    Cosmetic(
      id: 'wordly_theme_ocean',
      name: 'Ocean',
      tagline: 'Teal and sky blue.',
      price: 1000,
      look: WordlyLook(
        correct: (Color(0xFF63E6BE), Color(0xFF0CA678)),
        present: (Color(0xFF74C0FC), Color(0xFF228BE6)),
        absent: (Color(0xFF4A5A70), Color(0xFF2E3A4D)),
      ),
    ),
    Cosmetic(
      id: 'wordly_theme_sunset',
      name: 'Sunset',
      tagline: 'Coral and amber.',
      price: 1500,
      look: WordlyLook(
        correct: (Color(0xFFFF8787), Color(0xFFF03E3E)),
        present: (Color(0xFFFFD43B), Color(0xFFF59F00)),
        absent: (Color(0xFF6B4A5A), Color(0xFF45303B)),
      ),
    ),
    Cosmetic(
      id: 'wordly_theme_neon',
      name: 'Neon',
      tagline: 'Glowing green and magenta.',
      price: 2500,
      look: WordlyLook(
        correct: (Color(0xFF39FF88), Color(0xFF00C853)),
        present: (Color(0xFFFF5FE5), Color(0xFFD600B8)),
        absent: (Color(0xFF3A3A55), Color(0xFF1F1F33)),
      ),
    ),
    Cosmetic(
      id: 'wordly_theme_gold',
      name: 'Gold & Silver',
      tagline: 'Medals for every letter.',
      price: 4000,
      look: WordlyLook(
        correct: (Color(0xFFFFE27A), Color(0xFFD4A017)),
        present: (Color(0xFFF1F3F5), Color(0xFFADB5BD)),
        absent: (Color(0xFF6B5A3A), Color(0xFF453A24)),
      ),
    ),
  ];

  static WordlyLook get current => CosmeticStore.instance.pick(slot, all).look;
}

// -------------------------------------------------------- Snakes & Ladders

class SnlLook {
  const SnlLook({required this.rows, this.number = const Color(0xCC2A1A00)});

  /// Tile colours (light, dark) per pair of rows, bottom to top.
  final List<(Color, Color)> rows;

  /// Square numbers.
  final Color number;

  static const slot = 'snl_theme';

  static const all = <Cosmetic<SnlLook>>[
    Cosmetic(
      id: 'snl_theme_classic',
      name: 'Classic',
      tagline: 'Bright playground colours.',
      price: 0,
      look: SnlLook(
        rows: [
          (Color(0xFFFFE680), Color(0xFFFFD23F)),
          (Color(0xFFA6F28F), Color(0xFF7CD95F)),
          (Color(0xFF9FD4FF), Color(0xFF6BB8FF)),
          (Color(0xFFFFB38A), Color(0xFFFF9160)),
          (Color(0xFFD7B8FF), Color(0xFFBE92FF)),
        ],
      ),
    ),
    Cosmetic(
      id: 'snl_theme_candy',
      name: 'Candy',
      tagline: 'Pinks, peaches and cream.',
      price: 500,
      look: SnlLook(
        rows: [
          (Color(0xFFFFD6E7), Color(0xFFFFADD0)),
          (Color(0xFFFFE8CC), Color(0xFFFFCF99)),
          (Color(0xFFFCC2D7), Color(0xFFF783AC)),
          (Color(0xFFFFF0F6), Color(0xFFFFDEEB)),
          (Color(0xFFEEBEFA), Color(0xFFDA77F2)),
        ],
      ),
    ),
    Cosmetic(
      id: 'snl_theme_jungle',
      name: 'Jungle',
      tagline: 'Where the snakes feel at home.',
      price: 800,
      look: SnlLook(
        rows: [
          (Color(0xFFB2F2BB), Color(0xFF69DB7C)),
          (Color(0xFFD8F5A2), Color(0xFFA9E34B)),
          (Color(0xFF96F2D7), Color(0xFF38D9A9)),
          (Color(0xFFE9D8A6), Color(0xFFCDB57B)),
          (Color(0xFF8CE99A), Color(0xFF40C057)),
        ],
      ),
    ),
    Cosmetic(
      id: 'snl_theme_ocean',
      name: 'Ocean',
      tagline: 'Climb from the deep to the surface.',
      price: 1500,
      look: SnlLook(
        rows: [
          (Color(0xFF74C0FC), Color(0xFF4DABF7)),
          (Color(0xFF99E9F2), Color(0xFF66D9E8)),
          (Color(0xFFA5D8FF), Color(0xFF74C0FC)),
          (Color(0xFFC5F6FA), Color(0xFF99E9F2)),
          (Color(0xFFE7F5FF), Color(0xFFD0EBFF)),
        ],
      ),
    ),
    Cosmetic(
      id: 'snl_theme_midnight',
      name: 'Midnight',
      tagline: 'A board for late-night games.',
      price: 2500,
      look: SnlLook(
        rows: [
          (Color(0xFF2B2D5A), Color(0xFF1E2046)),
          (Color(0xFF34306B), Color(0xFF262354)),
          (Color(0xFF253A66), Color(0xFF1A2B50)),
          (Color(0xFF3C2A63), Color(0xFF2C1E4D)),
          (Color(0xFF233F5C), Color(0xFF182E45)),
        ],
        number: Color(0xDDE9ECFF),
      ),
    ),
    Cosmetic(
      id: 'snl_theme_gold',
      name: 'Treasure',
      tagline: 'Every square is gold.',
      price: 4000,
      look: SnlLook(
        rows: [
          (Color(0xFFFFE680), Color(0xFFF5C400)),
          (Color(0xFFFFF3B0), Color(0xFFFFD43B)),
          (Color(0xFFFFD966), Color(0xFFE0A800)),
          (Color(0xFFFFF9DB), Color(0xFFFFE066)),
          (Color(0xFFFFC94D), Color(0xFFD99A00)),
        ],
        number: Color(0xCC4A3200),
      ),
    ),
  ];

  static SnlLook get current => CosmeticStore.instance.pick(slot, all).look;
}
