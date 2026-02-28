import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/app_mode_controller.dart';
import 'package:hash/app/modules/home/views/hub_root.dart';
import 'package:shimmer/shimmer.dart';

class HashHubSplashScreen extends StatefulWidget {
  const HashHubSplashScreen({super.key});

  @override
  State<HashHubSplashScreen> createState() => _HashHubSplashScreenState();
}

class _HashHubSplashScreenState extends State<HashHubSplashScreen> {
  Timer? _timer;
  Timer? _fallbackTimer;
  bool _isNavigating = false;
  late final DateTime _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    final modeController = Get.isRegistered<AppModeController>()
        ? Get.find<AppModeController>()
        : Get.put(AppModeController(), permanent: true);
    modeController.setMode(AppMode.hub);

    _timer = Timer(const Duration(milliseconds: 1100), () {
      unawaited(_goNext());
    });
    // Safety fallback: never stay stuck on this splash.
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      unawaited(_goNext(force: true));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _goNext({bool force = false}) async {
    if (!mounted) return;
    if (_isNavigating && !force) return;
    _isNavigating = true;

    if (!force) {
      const minVisibleDuration = Duration(milliseconds: 900);
      final elapsed = DateTime.now().difference(_enteredAt);
      if (elapsed < minVisibleDuration) {
        await Future<void>.delayed(minVisibleDuration - elapsed);
        if (!mounted) return;
      }
    }

    try {
      await Get.offAll(
        () => const HubRoot(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 280),
      );
    } catch (error) {
      debugPrint('HashHubSplash navigation retry due to: $error');
      if (!mounted) return;
      await Get.offAll(
        () => const HubRoot(),
        transition: Transition.noTransition,
        duration: Duration.zero,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.9),
          period: const Duration(seconds: 2),
          direction: ShimmerDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/nologoblack.png',
                width: 220,
              ),
              const SizedBox(height: 10),
              Text(
                'LEVEL UP YOUR GAME',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
