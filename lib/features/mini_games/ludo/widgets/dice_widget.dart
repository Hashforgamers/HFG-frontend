import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/ludo/ludo_provider.dart';

import 'package:provider/provider.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../constants.dart';
import '../skins/ludo_dice_skin.dart';

///Widget for the dice
class DiceWidget extends StatelessWidget {
  const DiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, child) => RippleAnimation(
        color: value.gameState == LudoGameState.throwDice
            ? value.currentPlayer.color
            : Colors.transparent,
        ripplesCount: 3,
        minRadius: 30,
        repeat: true,
        child: CupertinoButton(
          onPressed:
              value.isMyTurn &&
                  !value.diceStarted &&
                  value.gameState == LudoGameState.throwDice
              ? value.throwDice
              : null,
          padding: const EdgeInsets.only(),
          child: LudoDice(
            skin: LudoDiceSkin.byId(value.currentDice),
            value: value.diceResult,
            rolling: value.diceStarted,
          ),
        ),
      ),
    );
  }
}
