import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ludo_provider.dart';
import 'main_screen.dart';

class LudoGameScreen extends StatelessWidget {
  const LudoGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LudoProvider()..startGame(),
      child: const _LudoRoot(),
    );
  }
}

class _LudoRoot extends StatefulWidget {
  const _LudoRoot({super.key});

  @override
  State<_LudoRoot> createState() => _LudoRootState();
}

class _LudoRootState extends State<_LudoRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        precacheImage(
          const AssetImage("assets/ludo/images/thankyou.gif"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/board.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/1.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/2.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/3.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/4.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/5.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/6.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/dice/draw.gif"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/crown/1st.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/crown/2nd.png"),
          context,
        ),
        precacheImage(
          const AssetImage("assets/ludo/images/crown/3rd.png"),
          context,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MainScreen(), // this is your game’s original screen
    );
  }
}
