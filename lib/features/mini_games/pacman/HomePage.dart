import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:hash/features/mini_games/pacman/path.dart';
import 'package:hash/features/mini_games/pacman/pixel.dart';
import 'package:hash/features/mini_games/pacman/player.dart';

import 'ghost.dart';
import 'ghost2.dart';
import 'ghost3.dart';

class PacManHome extends StatefulWidget {
  @override
  _PacManHomeState createState() => _PacManHomeState();
}

class _PacManHomeState extends State<PacManHome> {
  static int numberInRow = 11;
  int numberOfSquares = numberInRow * 16;
  int player = numberInRow * 14 + 1;
  int ghost = numberInRow * 2 - 2;
  int ghost2 = numberInRow * 9 - 1;
  int ghost3 = numberInRow * 11 - 2;

  bool preGame = true;
  bool mouthClosed = false;
  int score = 0;
  bool paused = false;

  // 🎵 Latest audioplayers
  late AudioPlayer bgmPlayer;
  late AudioPlayer sfxPlayer;

  // game data
  List<int> barriers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, /* … shortened */];
  List<int> food = [];
  String direction = "right";
  String ghostLast = "left";
  String ghostLast2 = "left";
  String ghostLast3 = "down";

  @override
  void initState() {
    super.initState();
    bgmPlayer = AudioPlayer();
    sfxPlayer = AudioPlayer();
  }

  Future<void> playBgm(String file, {bool loop = true}) async {
    await bgmPlayer.stop();
    await bgmPlayer.play(AssetSource(file));
    if (loop) {
      bgmPlayer.setReleaseMode(ReleaseMode.loop);
    }
  }

  Future<void> playSfx(String file) async {
    await sfxPlayer.play(AssetSource(file));
  }

  void startGame() {
    if (preGame) {
      preGame = false;
      getFood();
      playBgm('assets/pacman/pacman_beginning.wav');

      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (paused) return;

        // check collisions
        if (player == ghost || player == ghost2 || player == ghost3) {
          bgmPlayer.stop();
          playSfx('assets/pacman/pacman_death.wav');
          setState(() => player = -1);

          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Center(child: Text("Game Over!")),
              content: Text("Your Score : $score"),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetGame();
                  },
                  child: const Text('Restart'),
                ),
              ],
            ),
          );
        }
      });

      Timer.periodic(const Duration(milliseconds: 190), (timer) {
        if (!paused) {
          moveGhost();
          moveGhost2();
          moveGhost3();
        }
      });

      Timer.periodic(const Duration(milliseconds: 170), (timer) {
        if (!mounted) timer.cancel();
        if (!paused) {
          setState(() => mouthClosed = !mouthClosed);

          if (food.contains(player)) {
            playSfx('assets/pacman/pacman_chomp.wav');
            setState(() {
              food.remove(player);
              score++;
            });
          }

          switch (direction) {
            case "left":
              moveLeft();
              break;
            case "right":
              moveRight();
              break;
            case "up":
              moveUp();
              break;
            case "down":
              moveDown();
              break;
          }
        }
      });
    }
  }

  void resetGame() {
    setState(() {
      player = numberInRow * 14 + 1;
      ghost = numberInRow * 2 - 2;
      ghost2 = numberInRow * 9 - 1;
      ghost3 = numberInRow * 11 - 2;
      paused = false;
      preGame = true;
      mouthClosed = false;
      direction = "right";
      food.clear();
      score = 0;
    });
    startGame();
  }

  void getFood() {
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barriers.contains(i)) {
        food.add(i);
      }
    }
  }

  // movement functions (same as your code) ↓
  void moveLeft() {
    if (!barriers.contains(player - 1)) {
      setState(() => player--);
    }
  }

  void moveRight() {
    if (!barriers.contains(player + 1)) {
      setState(() => player++);
    }
  }

  void moveUp() {
    if (!barriers.contains(player - numberInRow)) {
      setState(() => player -= numberInRow);
    }
  }

  void moveDown() {
    if (!barriers.contains(player + numberInRow)) {
      setState(() => player += numberInRow);
    }
  }

  // ghost logic unchanged (keep your switch cases)
  void moveGhost() { /* … use your same logic … */ }
  void moveGhost2() { /* … */ }
  void moveGhost3() { /* … */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: (MediaQuery.of(context).size.height.toInt() * 0.0139).toInt(),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) direction = "down";
                if (details.delta.dy < 0) direction = "up";
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) direction = "right";
                if (details.delta.dx < 0) direction = "left";
              },
              child: GridView.builder(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.1,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: numberOfSquares,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: numberInRow,
                ),
                itemBuilder: (context, index) {
                  if (mouthClosed && player == index) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    );
                  } else if (player == index) {
                    switch (direction) {
                      case "left":
                        return Transform.rotate(angle: pi, child: MyPlayer());
                      case "up":
                        return Transform.rotate(angle: 3 * pi / 2, child: MyPlayer());
                      case "down":
                        return Transform.rotate(angle: pi / 2, child: MyPlayer());
                      default:
                        return MyPlayer();
                    }
                  } else if (ghost == index) return MyGhost();
                  else if (ghost2 == index) return MyGhost2();
                  else if (ghost3 == index) return MyGhost3();
                  else if (barriers.contains(index)) {
                    return MyPixel(
                      innerColor: Colors.blue[900],
                      outerColor: Colors.blue[800],
                    );
                  } else if (preGame || food.contains(index)) {
                    return MyPath(innerColor: Colors.yellow, outerColor: Colors.black);
                  } else {
                    return MyPath(innerColor: Colors.black, outerColor: Colors.black);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(" Score : $score",
                    style: const TextStyle(color: Colors.white, fontSize: 23)),
                GestureDetector(
                  onTap: startGame,
                  child: const Text("P L A Y",
                      style: TextStyle(color: Colors.white, fontSize: 23)),
                ),
                GestureDetector(
                  child: Icon(paused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white),
                  onTap: () {
                    setState(() => paused = !paused);
                    if (paused) {
                      bgmPlayer.pause();
                      playSfx('assets/pacman/pacman_intermission.wav');
                    } else {
                      bgmPlayer.resume();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
