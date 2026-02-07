import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/splash_controller.dart';

class SplashView extends StatelessWidget {
  SplashView({super.key}) {
    Get.put(SplashController()); // Register the controller ONCE
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
