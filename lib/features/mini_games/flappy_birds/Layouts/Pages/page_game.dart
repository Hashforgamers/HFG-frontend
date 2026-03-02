// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, avoid_unnecessary_containers
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../Database/database.dart';
import '../../Global/constant.dart';
import '../../Global/functions.dart';
import '../../Resources/strings.dart';
import '../Widgets/widget_barrier.dart';
import '../Widgets/widget_bird.dart';
import '../Widgets/widget_cover.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';

class GamePage extends StatefulWidget {
  GamePage({Key? key}) : super(key: key);
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Timer? _movementTimer;
  Timer? _scoreTimer;

  @override
  void initState() {
    super.initState();
    // Ensure persisted settings/scores are loaded even when opening game directly.
    init();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _scoreTimer?.cancel();
    stopFlappyAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gameHasStarted ? jump : startGame,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: background(Str.image),
                child: Stack(
                  children: [
                    Bird(yAxis, birdWidth, birdHeight),
                    // Tap to play text
                    Container(
                      alignment: Alignment(0, -0.3),
                      child: myText(
                        gameHasStarted ? '' : 'TAP TO START',
                        Colors.white,
                        25,
                      ),
                    ),
                    Barrier(
                      barrierHeight[0][0],
                      barrierWidth,
                      barrierX[0],
                      true,
                    ),
                    Barrier(
                      barrierHeight[0][1],
                      barrierWidth,
                      barrierX[0],
                      false,
                    ),
                    Barrier(
                      barrierHeight[1][0],
                      barrierWidth,
                      barrierX[1],
                      true,
                    ),
                    Barrier(
                      barrierHeight[1][1],
                      barrierWidth,
                      barrierX[1],
                      false,
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      left: 1,
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "Score : $score",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontFamily: "Magic4",
                              ),
                            ), // Best TEXT
                            Text(
                              "Best : $topScore",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontFamily: "Magic4",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 1, child: Cover()),
          ],
        ),
      ),
    );
  }

  // Jump Function:
  void jump() {
    setState(() {
      time = 0;
      initialHeight = yAxis;
    });
  }

  //Start Game Function:
  void startGame() {
    gameHasStarted = true;
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(Duration(milliseconds: 35), (timer) {
      height = gravity * time * time + velocity * time;
      setState(() {
        yAxis = initialHeight - height;
      });
      /* <  Barriers Movements  > */
      setState(() {
        if (barrierX[0] < screenEnd) {
          barrierX[0] += screenStart;
        } else {
          barrierX[0] -= barrierMovement;
        }
      });
      setState(() {
        if (barrierX[1] < screenEnd) {
          barrierX[1] += screenStart;
        } else {
          barrierX[1] -= barrierMovement;
        }
      });
      if (birdIsDead()) {
        timer.cancel();
        _movementTimer = null;
        _showDialog();
      }
      time += 0.032;
    });
    /* <  Calculate Score  > */
    _scoreTimer?.cancel();
    _scoreTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (birdIsDead()) {
        // Todo : save the top score in the database  <---
        write("score", topScore);
        MiniGameScoreService().recordScore('laggy_bird', topScore);
        timer.cancel();
        _scoreTimer = null;
        score = 0;
      } else {
        setState(() {
          if (score == topScore) {
            topScore++;
          }
          score++;
        });
      }
    });
  }

  /// Make sure the [Bird] doesn't go out screen & hit the barrier
  bool birdIsDead() {
    // Screen
    if (yAxis > 1.26 || yAxis < -1.1) {
      return true;
    }

    /// Barrier hitBox
    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= birdWidth &&
          (barrierX[i] + (barrierWidth)) >= birdWidth &&
          (yAxis <= -1 + barrierHeight[i][0] ||
              yAxis + birdHeight >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    _movementTimer?.cancel();
    _scoreTimer?.cancel();
    _movementTimer = null;
    _scoreTimer = null;
    Navigator.pop(context); // dismisses the alert dialog
    setState(() {
      yAxis = 0;
      gameHasStarted = false;
      time = 0;
      score = 0;
      initialHeight = yAxis;
      barrierX[0] = 2;
      barrierX[1] = 3.4;
    });
  }

  // TODO: Alert Dialog with 2 options (try again, exit)
  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: myText("..Oops", Colors.blue[900], 35),
          actionsPadding: EdgeInsets.only(right: 8, bottom: 8),
          content: Container(
            child: Lottie.asset(
              "assets/flappy_birds/pics/loss.json",
              fit: BoxFit.cover,
            ),
          ),
          actions: [
            gameButton(
              () {
                resetGame();
                stopFlappyAudio();
                // Exit to previous screen instead of pushing a nested home view.
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              "Exit",
              Colors.grey,
            ),
            gameButton(
              () {
                resetGame();
              },
              "try again",
              const Color(0xff00DC00),
            ),
          ],
        );
      },
    );
  }
}
