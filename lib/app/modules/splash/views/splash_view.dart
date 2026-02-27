import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Final safety net: never stay stuck on splash indefinitely.
    Future<void>.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      if (Get.currentRoute == AppRoutes.SPLASH) {
        Get.offAllNamed(AppRoutes.LOGIN);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.9),
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
