import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../../core/configs/assets/app_images.dart';
import '../../../core/configs/theme/app_colors.dart';
import '../../../main_router_game.dart';

class InteractiveButtonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<MainRouterGame> {
  final List<String> texts = ['easy', 'medium', 'hard'];
  final List<String> imagePaths = [
    AppImages.cherry,
    AppImages.banana,
    AppImages.kiwi,
  ];

  late SpriteComponent spriteComponent;
  late TextComponent textComponent;

  InteractiveButtonComponent({
    super.position,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 22,
        color: AppColors.white,
        fontFamily: 'Marshmallow',
        letterSpacing: 3.0,
      ),
    );

    final int currentMode = game.getMode();

    final initialImage = await Flame.images.load(imagePaths[currentMode]);
    spriteComponent = SpriteComponent(
      sprite: Sprite(initialImage),
      size: size,
    );

    textComponent = TextComponent(
      text: texts[currentMode],
      position: Vector2(size.x / 2, size.y + 10),
      anchor: Anchor.topCenter,
      textRenderer: textPaint,
    );

    add(spriteComponent);
    add(textComponent);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _nextState();
  }

  void _nextState() async {
    final newMode = (game.getMode() + 1) % texts.length;

    game.saveMode(newMode);

    textComponent.text = texts[newMode];

    final newImage = await Flame.images.load(imagePaths[newMode]);
    spriteComponent.sprite = Sprite(newImage);
  }
}
