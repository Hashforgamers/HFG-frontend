import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hash/core/utils/haptics.dart';
import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final segementService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  LoginView({super.key});

  bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: Container(
        color: const Color(0xff191919),
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

            // Google Sign-In
            SafeArea(
              child: Stack(
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
                          Image.asset(
                            'assets/Google__G__logo.svg.png',
                            height: 20,
                            width: 20,
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
            ),

            // Apple Sign-In (iOS Only)
            if (isIOS)
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
                        await controller.appleSignInWithRelayWarning(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/apple-logo-transparent.png',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Apple',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Phone Sign-In
            // const SizedBox(height: 12),
            // Stack(
            //   children: [
            //     SizedBox(
            //       width: double.infinity,
            //       height: 50,
            //       child: RGBLightFrame(
            //         width: Get.width,
            //         height: Get.height,
            //         borderRadius: 12,
            //       ),
            //     ),
            //     Positioned.fill(
            //       child: ElevatedButton(
            //         onPressed: () => _showPhoneAuthSheet(context),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.transparent,
            //           shadowColor: Colors.transparent,
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //         ),
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             const Icon(Icons.sms, color: Colors.white, size: 20),
            //             const SizedBox(width: 10),
            //             Text(
            //               'Continue with Phone',
            //               style: GoogleFonts.inter(
            //                 color: Colors.white,
            //                 fontSize: 16,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
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
                      'Welcome to\nHash for Gamers',
                      textAlign: TextAlign.center,
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
              child: const Center(child: RainbowLoadingBar()),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showPhoneAuthSheet(BuildContext context) {
    controller.resetPhoneFlow();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Obx(
              () => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.otpSent.value ? 'Verify OTP' : 'Sign in with Phone',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                if (!controller.otpSent.value) ...[
                  // Country code + phone row
                  Row(
                    children: [
                      // Country code dropdown (minimal, no plugins)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButton<String>(
                          value: controller.selectedDialCode.value,
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: GoogleFonts.inter(color: Colors.white),
                          items: controller.supportedDialCodes
                              .map(
                                (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) controller.selectedDialCode.value = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.phoneController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white),
                          cursorColor: Colors.white70,
                          enableInteractiveSelection: false, // block paste/selection
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15), // multi-country
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            hintText: 'Phone number',
                            hintStyle: GoogleFonts.inter(color: Colors.white54),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isStartingPhone.value
                          ? null
                          : () async {
                        await Haptics.medium();
                        await controller.startPhoneSignIn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Obx(() {
                        return controller.isStartingPhone.value
                            ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Send OTP', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600));
                      }),
                    ),
                  ),
                ] else ...[
                  // OTP input
                  TextField(
                    controller: controller.otpController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: Colors.white70,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      hintText: 'Enter 6-digit OTP',
                      hintStyle: GoogleFonts.inter(color: Colors.white54),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Countdown + Resend
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.secondsLeft.value > 0
                                ? 'Resend in ${controller.secondsLeft.value}s'
                                : 'Didn’t get the code?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: controller.secondsLeft.value > 0
                            ? null
                            : () async {
                          await Haptics.selection();
                          await controller.resendCode();
                        },
                        child: Text(
                          'Resend',
                          style: GoogleFonts.inter(
                            color: controller.secondsLeft.value > 0 ? Colors.white24 : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Verify
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isVerifyingOtp.value
                          ? null
                          : () async {
                        await Haptics.medium();
                        await controller.verifyOtpAndSignIn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Obx(() {
                        return controller.isVerifyingOtp.value
                            ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Verify & Continue',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600));
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
