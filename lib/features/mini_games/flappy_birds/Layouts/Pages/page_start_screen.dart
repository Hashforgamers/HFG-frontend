// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_rate_us.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_settings.dart';
import 'page_game.dart';
import '../../Global/constant.dart';
import '../../Global/functions.dart';
import '../../Resources/strings.dart';
import '../Widgets/widget_bird.dart';
import '../Widgets/widget_gradient _button.dart';

class FlappyBirds extends StatefulWidget {
  const FlappyBirds({Key? key}) : super(key: key);
  @override
  State<FlappyBirds> createState() => _FlappyBirdsState();
}

class _FlappyBirdsState extends State<FlappyBirds> {
  @override
  void initState() {
    // Todo : initialize the database  <---
    init();
    super.initState();
  }

  @override
  void dispose() {
    stopFlappyAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: background(Str.image),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FittedBox(child: myText("FlappyBird", Colors.white, 70)),
              const SizedBox(height: 12),
              Bird(yAxis, birdWidth, birdHeight),
              const SizedBox(height: 20),
              _buttons(),
              const Spacer(flex: 2),
              const AboutUs(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// three buttons
Column _buttons() {
  return Column(
    children: [
      Button(
        buttonType: "text",
        height: 60,
        width: 278,
        icon: Icon(
          Icons.play_arrow_rounded,
          size: 60,
          color: const Color(0xff00DC00),
        ),
        onTap: () => Get.to(() => GamePage()), // direct navigation
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Button(
            buttonType: "icon",
            height: 60,
            width: 110,
            icon: Icon(Icons.settings, size: 40, color: Colors.grey.shade900),
            onTap: () => Get.to(() => Settings()),
          ),
          Button(
            buttonType: "icon",
            height: 60,
            width: 110,
            icon: Icon(Icons.star, size: 40, color: Colors.deepOrange),
            onTap: () => Get.to(() => RateUs()),
          ),
        ],
      ),
    ],
  );
}

class AboutUs extends StatelessWidget {
  const AboutUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return dialog(context);
          },
        );
      },
      child: myText("About Us", Colors.white, 20),
    );
  }
}
