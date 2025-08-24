import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart' hide Game;
import 'package:flame/rendering.dart';
import 'package:flame/text.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/features/mini_games/fruit_ninja/common/widgets/button/rounded_button.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/constants/app_router.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/theme/app_colors.dart';
import 'package:hash/features/mini_games/fruit_ninja/main_router_game.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Secure API call placeholder (you'll replace this with your real service)
Future<void> submitScoreToAPI(Map<String, dynamic> payload) async {
  // TODO: Replace with actual POST to your backend
  debugPrint("Submitting score securely: $payload");
}

class VictoryRoute extends Route {
  VictoryRoute() : super(GameVictoryPage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    previousRoute!
      ..stopTime()
      ..addRenderEffect(
        PaintDecorator.grayscale(opacity: 0.5)..addBlur(3.0),
      );
  }

  @override
  void onPop(Route nextRoute) {
    nextRoute
      ..resumeTime()
      ..removeRenderEffect();
  }
}

class GameVictoryPage extends Component with TapCallbacks, HasGameReference<MainRouterGame> {
  late TextComponent _textComponent;
  late TextComponent _textTimeComponent;
  late TextComponent _textScoreComponent;
  late TextComponent _textLeaderboardComponent;
  late TextComponent _textGameModeComponent;

  late RoundedButton _buttonNewGameComponent;

  final String timezone = 'UTC+7';

  @override
  Future<void> onLoad() async {
    final textTitlePaint = TextPaint(
      style: const TextStyle(
        fontSize: 80,
        color: AppColors.white,
        fontFamily: 'Marshmallow',
        letterSpacing: 3.0,
      ),
    );

    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final textTimePaint = TextPaint(
      style: const TextStyle(
        fontSize: 25,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final textScorePaint = TextPaint(
      style: const TextStyle(
        fontSize: 35,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    _buttonNewGameComponent = RoundedButton(
      bgColor: AppColors.githubColor,
      borderColor: AppColors.blue,
      text: "New Game",
      anchor: Anchor.center,
      onPressed: () {
        game.router
          ..pop()
          ..pushNamed(AppRouter.homePage, replace: true);
      },
    );

    add(_buttonNewGameComponent);

    final flameGame = findGame()!;

    final mode = game.getMode();
    final modeText = mode == 0 ? 'Easy' : mode == 1 ? 'Medium' : 'Hard';

    addAll([
      _textComponent = TextComponent(
        text: 'VICTORY',
        position: flameGame.canvasSize / 2,
        anchor: Anchor.center,
        children: [
          ScaleEffect.to(
            Vector2.all(1.1),
            EffectController(duration: 0.3, alternate: true, infinite: true),
          ),
        ],
        textRenderer: textTitlePaint,
      ),
      _textTimeComponent = TextComponent(
        text: "",
        position: flameGame.canvasSize / 2,
        anchor: Anchor.centerLeft,
        textRenderer: textTimePaint,
      ),
      _textLeaderboardComponent = TextComponent(
        text: "Click anywhere to save Rankings",
        position: flameGame.canvasSize / 2,
        anchor: Anchor.centerRight,
        textRenderer: textPaint,
      ),
      _textScoreComponent = TextComponent(
        text: 'Score: ',
        position: flameGame.canvasSize / 2,
        anchor: Anchor.center,
        textRenderer: textScorePaint,
      ),
      _textGameModeComponent = TextComponent(
        text: "Mode: $modeText",
        position: flameGame.canvasSize / 2,
        anchor: Anchor.centerLeft,
        textRenderer: textPaint,
      ),
    ]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _textComponent.position = Vector2(game.size.x / 2, game.size.y / 2 - 70);
    _textTimeComponent.position = Vector2(15, 20);
    _textScoreComponent.position = Vector2(game.size.x / 2, game.size.y / 2 + 25);
    _buttonNewGameComponent.position = Vector2(game.size.x / 2, game.size.y / 2 + 110);
    _textLeaderboardComponent.position = Vector2(game.size.x - 15, game.size.y - 15);
    _textGameModeComponent.position = Vector2(15, game.size.y - 15);

    _textScoreComponent.text = 'Score: ${game.getScore()}';
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void update(double dt) {
    super.update(dt);

    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));
    String formattedTime = DateFormat('MM/dd/yyyy HH:mm').format(now);

    if (_textTimeComponent.text != '$formattedTime ($timezone)') {
      _textTimeComponent.text = '$formattedTime ($timezone)';
    }
  }

  @override
  Future<void> onTapUp(TapUpEvent event) async {
    await captureAndSaveImage();

    // 🔒 Submit secure score
    final payload = game.getScorePayload();
    await submitScoreToAPI(payload);
  }

  Future<void> captureAndSaveImage() async {
    try {
      final recorder = PictureRecorder();
      final rect = Rect.fromLTWH(0.0, 0.0, game.size.x, game.size.y);
      final canvas = Canvas(recorder, rect);

      game.render(canvas);

      final image = await recorder.endRecording().toImage(game.size.x.toInt(), game.size.y.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }
}
