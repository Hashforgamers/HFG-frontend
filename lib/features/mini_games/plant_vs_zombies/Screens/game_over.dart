import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Constant/assets.dart';
import '../Utils/audio_player.dart';
import '../routes.dart';

class GameOver extends StatelessWidget {
  Future<void> _playSound() async {
    await AudioPlayer.playSound(Assets.game_over);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final int score = args is int ? args : int.tryParse('$args') ?? 0;
    _playSound();

    return Material(
      child: Center(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Game Over",
                style: GoogleFonts.pressStart2p(
                  fontSize: 35.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 25.0),
              Text(
                "Score: $score",
                style: GoogleFonts.pressStart2p(
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 25.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: OutlinedButton(
                  child: Text(
                    "Play Again",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.home,
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
          color: Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }
}
