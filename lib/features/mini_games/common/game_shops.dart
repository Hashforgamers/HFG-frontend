import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import 'cosmetic_shop_screen.dart';
import 'cosmetics.dart';
import 'game_looks.dart';

/// Opens a mini game's theme shop; completes when the player comes back.
Future<void> openCosmeticShop(
  BuildContext context, {
  required String title,
  required List<CosmeticTab> tabs,
}) {
  CosmeticStore.instance.load();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CosmeticShopScreen(title: title, tabs: tabs),
    ),
  );
}

/// The shop tabs (and item previews) of each themed mini game.
class GameShops {
  static final arrowEscape = [
    CosmeticTab(
      label: 'Themes',
      slot: ArrowLook.slot,
      items: ArrowLook.all,
      preview: (item) => _arrows(item.look as ArrowLook),
    ),
  ];

  static final pacMan = [
    CosmeticTab(
      label: 'Themes',
      slot: PacLook.slot,
      items: PacLook.all,
      preview: (item) => _maze(item.look as PacLook),
    ),
  ];

  static final wordly = [
    CosmeticTab(
      label: 'Themes',
      slot: WordlyLook.slot,
      items: WordlyLook.all,
      preview: (item) => _tiles(item.look as WordlyLook),
    ),
  ];

  static final snakesLadders = [
    CosmeticTab(
      label: 'Boards',
      slot: SnlLook.slot,
      items: SnlLook.all,
      preview: (item) => _squares(item.look as SnlLook),
    ),
  ];

  static Widget _frame({
    required Widget child,
    Gradient? gradient,
    Color? color,
  }) => Container(
    width: 230,
    height: 76,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GameColors.outline, width: 2.5),
    ),
    child: child,
  );

  static Widget _arrows(ArrowLook look) => _frame(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [look.boardTop, look.boardBottom],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, color) in look.palette.take(5).indexed)
          Stack(
            alignment: Alignment.center,
            children: [
              for (final (size, c) in [(40.0, look.outline), (30.0, color)])
                Icon(
                  const [
                    Icons.north_rounded,
                    Icons.east_rounded,
                    Icons.south_rounded,
                    Icons.west_rounded,
                    Icons.north_east_rounded,
                  ][i],
                  size: size,
                  color: c,
                ),
            ],
          ),
      ],
    ),
  );

  static Widget _maze(PacLook look) => _frame(
    color: look.background,
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: look.wall,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: look.wallLine, width: 2.5),
        boxShadow: [
          BoxShadow(color: look.wallLine.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GameColors.outline, width: 2),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [look.pacLight, look.pacDark],
              ),
            ),
          ),
          for (var i = 0; i < 6; i++)
            Expanded(
              child: Center(
                child: Container(
                  width: i == 5 ? 12 : 6,
                  height: i == 5 ? 12 : 6,
                  decoration: BoxDecoration(
                    color: look.dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  static Widget _tiles(WordlyLook look) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (letter, colors) in [
        ('W', look.correct),
        ('O', look.present),
        ('R', look.absent),
        ('D', look.correct),
        ('S', look.present),
      ])
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameColors.outline, width: 2.5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.$1, colors.$2],
            ),
          ),
          child: Text(letter, style: gameFont(20, Colors.white)),
        ),
    ],
  );

  static Widget _squares(SnlLook look) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top rows first, as on the board.
        for (final (r, (light, dark)) in look.rows.reversed.indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < 8; c++)
                Container(
                  width: 26,
                  height: 20,
                  alignment: Alignment.center,
                  color: (r + c).isEven ? light : dark,
                  child: Text(
                    '${(look.rows.length - r) * 20 - c}',
                    style: gameFont(9, look.number),
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}
