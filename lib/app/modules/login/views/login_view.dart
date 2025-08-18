import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final segementService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: Container(color: Color(0xff191919),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Login',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RGBLightFrame(
                    width: Get.width,
                    height: Get.height,
                    borderRadius: 12,
                  ),
                ),
                Positioned.fill(
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.googleSignIn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755475120/Google__G__logo.svg_iywk14.png',
                          height: 20,
                          width: 20,
                          placeholder: (context, url) => const SizedBox(
                            height: 20,
                            width: 20,
                            child: RainbowLoadingBar(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // logo
                    Image.asset('assets/logo.png', width: 160),
                    const SizedBox(height: 25),

                    // Tag-line
                    Text(
                      'Welcome to\nHash for Gamers',textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // overlay loader
          Obx(
                () => controller.isLoading.value
                ? Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: RainbowLoadingBar()
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
