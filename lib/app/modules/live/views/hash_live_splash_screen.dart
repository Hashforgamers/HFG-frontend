import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/live/views/hash_live_root.dart';
import 'package:hash/app/modules/live/widgets/live_ui.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:video_player/video_player.dart';

class HashLiveSplashScreen extends StatefulWidget {
  const HashLiveSplashScreen({super.key});

  @override
  State<HashLiveSplashScreen> createState() => _HashLiveSplashScreenState();
}

class _HashLiveSplashScreenState extends State<HashLiveSplashScreen> {
  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _navigated = false;
  String? _initError;
  bool _isInitializing = true;
  late final DateTime _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    unawaited(Haptics.liveEnterBurst(duration: const Duration(seconds: 3)));
    final modeController = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);
    modeController.setMode(AppMode.live);

    _initializeVideo();
    _scheduleFallbackNavigation();
  }

  Future<void> _initializeVideo() async {
    const assetCandidates = [
      'assets/live_splash.mp4',
      'assets/videos/live_splash.mp4',
    ];

    for (final assetPath in assetCandidates) {
      final controller = VideoPlayerController.asset(assetPath);
      try {
        await controller.initialize().timeout(const Duration(seconds: 5));
        if (!mounted) {
          await controller.dispose();
          return;
        }

        _videoController = controller
          ..setLooping(false)
          ..setVolume(0)
          ..play()
          ..addListener(_onVideoTick);

        setState(() {
          _initError = null;
          _isInitializing = false;
        });
        return;
      } catch (error) {
        debugPrint('HashLiveSplash video init failed for $assetPath: $error');
        await controller.dispose();
      }
    }

    if (!mounted) return;
    setState(() {
      _initError = 'video_init_failed';
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  void _scheduleFallbackNavigation() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 6), () {
      unawaited(_goNext());
    });
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration <= Duration.zero) return;
    final finished =
        c.value.position >= (duration - const Duration(milliseconds: 80));
    if (finished) {
      unawaited(_goNext());
    }
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    const minVisibleDuration = Duration(milliseconds: 1200);
    final elapsed = DateTime.now().difference(_enteredAt);
    if (elapsed < minVisibleDuration) {
      await Future<void>.delayed(minVisibleDuration - elapsed);
      if (!mounted) return;
    }

    unawaited(Haptics.success());
    Get.offAll(() => const HashLiveRoot());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: LiveUi.pageDecoration(),
        child: _videoController != null && _videoController!.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            : _initError != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hash Live',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Video format not supported on this device.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Entering Hash Live…',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_isInitializing)
                      const SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
