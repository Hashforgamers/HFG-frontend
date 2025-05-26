import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:video_player/video_player.dart';
import '../../../../utils/widgets/glow_neon_loader.dart';
import '../controllers/splash_controller.dart';

class SplashView extends StatefulWidget {
  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final SplashController controller = Get.put(SplashController());
  late VideoPlayerController _videoController;
  final segementService = locator<SegmentSdkService>();

  @override
  void initState() {
    super.initState();
    segementService.onAppLaunch();
    _videoController = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);
        _videoController.addListener(() {
          if (!_videoController.value.isPlaying &&
              _videoController.value.position ==
                  _videoController.value.duration) {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LOADING'),
              RainbowGlowingLoader(size: 50),
            ],
          ),
        ),
      ),
    );
  }
}
