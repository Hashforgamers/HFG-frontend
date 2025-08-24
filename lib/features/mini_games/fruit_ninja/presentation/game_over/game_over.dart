import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame/text.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/features/mini_games/fruit_ninja/common/widgets/button/rounded_button.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/constants/app_router.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/theme/app_colors.dart';
import 'package:hash/features/mini_games/fruit_ninja/main_router_game.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/game.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Secure API call placeholder
Future<void> submitScoreToAPI(Map<String, dynamic> payload) async {
  debugPrint("Submitting score securely: $payload");
}

class GameOverRoute extends Route {
  GameOverRoute() : super(GameOverPage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    previousRoute!
      ..stopTime()
      ..addRenderEffect(PaintDecorator.grayscale(opacity: 0.5)..addBlur(3.0));
  }

  @override
  void onPop(Route nextRoute) {
    final routeChildren = nextRoute.children.whereType<GamePage>();
    if (routeChildren.isNotEmpty) {
      final gamePage = routeChildren.first;
      gamePage.removeAll(gamePage.children);
    }

    nextRoute
      ..resumeTime()
      ..removeRenderEffect();
  }
}

class GameOverPage extends Component with TapCallbacks, HasGameReference<MainRouterGame> {
  late TextComponent _textComponent;
  late TextComponent _textTimeComponent;
  late TextComponent _textScoreComponent;
  late TextComponent _textNewGameComponent;
  late TextComponent _textGameModeComponent;

  late RoundedButton _buttonLeaderboard;

  final String timezone = 'UTC+7';

  @override
  FutureOr<void> onLoad() {
    final textTitlePaint = TextPaint(
      style: const TextStyle(
        fontSize: 60,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final textTimePaint = TextPaint(
      style: TextStyle(
        fontSize: game.isDesktop ? 25 : 18,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final textPaint = TextPaint(
      style: TextStyle(
        fontSize: game.isDesktop ? 18 : 12,
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

    _buttonLeaderboard = RoundedButton(
      sizeX: 250,
      bgColor: AppColors.githubColor,
      borderColor: AppColors.blue,
      text: "Submit Score",
      anchor: Anchor.center,
      onPressed: () async {
        await captureAndSaveImage();

        // 🔐 Submit secure score
        final payload = game.getScorePayload();
        await submitScoreToAPI(payload);
      },
    );

    add(_buttonLeaderboard);

    final flameGame = findGame()!;
    final mode = game.getMode();
    final modeText = mode == 0 ? 'Easy' : mode == 1 ? 'Medium' : 'Hard';

    addAll([
      _textComponent = TextComponent(
        text: 'Game Over',
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
      _textNewGameComponent = TextComponent(
        text: "Click anywhere to start new Game",
        position: flameGame.canvasSize / 2,
        anchor: game.isDesktop ? Anchor.centerRight : Anchor.center,
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
        anchor: game.isDesktop ? Anchor.centerLeft : Anchor.center,
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
    _textScoreComponent.text = 'Score: ${game.getScore()}';

    _buttonLeaderboard.position = Vector2(game.size.x / 2, game.size.y / 2 + 110);

    _textNewGameComponent.position = game.isDesktop
        ? Vector2(game.size.x - 15, game.size.y - 15)
        : Vector2(game.size.x / 2, game.size.y - 15);

    _textGameModeComponent.position = game.isDesktop
        ? Vector2(15, game.size.y - 15)
        : Vector2(game.size.x / 2, game.size.y - 30);
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
  void onTapUp(TapUpEvent event) {
    game.router
      ..pop()
      ..pushNamed(AppRouter.homePage, replace: true);
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
