// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hash/core/service/segment_sdk_service.dart';
// import 'package:hash/core/service/fb_events_service.dart';
// import 'package:hash/core/service_locator.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
//
// import '../../../../utils/widgets/loader.dart';
// import '../../../../utils/widgets/rgb_light_frame.dart';
// import '../../login/controllers/login_controller.dart';
//
// class VerifyOtpView extends StatefulWidget {
//   final String verificationId;
//   const VerifyOtpView({super.key, required this.verificationId});
//
//   @override
//   State<VerifyOtpView> createState() => _VerifyOtpViewState();
// }
//
// class _VerifyOtpViewState extends State<VerifyOtpView> {
//   final TextEditingController _otpController = TextEditingController();
//   final segmentService   = locator<SegmentSdkService>();
//   final fbEventsService  = locator<FbEventsService>();
//   final LoginController  login = Get.find<LoginController>();
//
//   @override
//   void dispose() {
//     _otpController.dispose();
//     super.dispose();
//   }
//
//   // ─────────────────────────── UI ────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // ───── main content ─────────
//           SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // logo
//                     Image.asset('assets/logo.png', width: 140),
//                     const SizedBox(height: 30),
//
//                     // headline
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         'Verify OTP',
//                         style: GoogleFonts.orbitron(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//
//                     // subtitle
//                     Text(
//                       'Enter the 6-digit code we just sent to your phone',
//                       style: GoogleFonts.inter(
//                           color: Colors.white70, fontSize: 14),
//                     ),
//                     const SizedBox(height: 28),
//
//                     // OTP fields
//                     PinCodeTextField(
//                       appContext: context,
//                       length: 6,
//                       controller: _otpController,
//                       textStyle: GoogleFonts.inter(color: Colors.white),
//                       keyboardType: TextInputType.number,
//                       animationType: AnimationType.fade,
//                       enableActiveFill: true,
//                       backgroundColor: Colors.black,
//                       pinTheme: PinTheme(
//                         shape: PinCodeFieldShape.box,
//                         borderRadius: BorderRadius.circular(12),
//                         fieldHeight: 52,
//                         fieldWidth: 44,
//                         inactiveColor: Colors.white24,
//                         inactiveFillColor: Colors.black,
//                         activeColor: const Color(0xff00DC00),
//                         activeFillColor: Colors.black87,
//                         selectedColor: const Color(0xff00DC00),
//                         selectedFillColor: Colors.black,
//                       ),
//                       onCompleted: (_) => _verifyOtp(), // auto-trigger
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Neon “Verify” button
//                     Stack(
//                       children: [
//                         SizedBox(
//                           width: double.infinity,
//                           height: 54,
//                           child: RGBLightFrame(
//                             width: Get.width,
//                             height: Get.height,
//                             borderRadius: 12,
//                           ),
//                         ),
//                         Positioned.fill(
//                           child: ElevatedButton(
//                             onPressed:
//                                 login.isLoading.value ? null : _verifyOtp,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: Obx(() => login.isLoading.value
//                                 ? const RainbowLoadingBar(width: 280, height: 2)
//                                 : Text(
//                                     'Verify OTP',
//                                     style: GoogleFonts.inter(
//                                         color: Colors.white, fontSize: 16),
//                                   )),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 22),
//
//                     // Resend
//                     TextButton(
//                       onPressed: login.isLoading.value ? null : _resendOtp,
//                       child: Text(
//                         'Resend OTP',
//                         style: GoogleFonts.inter(color: const Color(0xff00DC00)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // ───── overlay loader ──────
//           Obx(() => login.isLoading.value
//               ? Container(
//                   color: Colors.black.withOpacity(0.55),
//                   child: const Center(
//                     child: RainbowLoadingBar(
//                       valueColor:
//                           AlwaysStoppedAnimation<Color>(Color(0xffDE3A3A)),
//                     ),
//                   ),
//                 )
//               : const SizedBox.shrink()),
//         ],
//       ),
//     );
//   }
//
//   // ─────────────────────────── ACTIONS ───────────────────────────
//   void _verifyOtp() {
//     final otp = _otpController.text.trim();
//     if (otp.length != 6) {
//       Get.snackbar('Error', 'Enter a valid 6-digit OTP',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white);
//       return;
//     }
//
//     login.isLoading.value = true;
//     login.verifyOtp(otp).then((_) {
//       segmentService.onOtpVerified(mobile: login.phoneNumberController.text);
//       fbEventsService.onOtpVerified(mobile: login.phoneNumberController.text);
//       login.isLoading.value = false;
//     });
//   }
//
//   void _resendOtp() {
//     // your resend logic …
//     Get.snackbar('Info', 'OTP resent',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.blue,
//         colorText: Colors.white);
//   }
// }
