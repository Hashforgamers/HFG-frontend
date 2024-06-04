import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../../utils/widgets/loader.dart';
import '../controllers/splash_controller.dart';

class SplashView extends StatefulWidget {
  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final SplashController controller = Get.put(SplashController());
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);
        _videoController.addListener(() {
          if (!_videoController.value.isPlaying &&
              _videoController.value.position == _videoController.value.duration) {
            controller.navigateToHome();
          }
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black,
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('LOADING'),
            RainbowLoadingBar(width: 80,height: 2,),
          ],
        ))
      ),
    );
  }
}
