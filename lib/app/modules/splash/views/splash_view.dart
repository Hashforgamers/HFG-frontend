import 'package:hash/utils/widgets/hash_splash_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/deeplink_service.dart';
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
        DeepLinkService.markAppReady();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const HashSplashLogo(),
    );
  }
}
