import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- required

class ContactSupport extends StatelessWidget {
  const ContactSupport({super.key});

  void _openWhatsApp() async {
    const phoneNumber = '+917400377854'; // TODO: Replace with your support number
    final message = Uri.encodeComponent(
      '''Hi HashforGamers Support 👋,

I need help with something.

Issue:
[Please describe your issue here]

Screenshot (if any):
[Attach if possible]''',
    );
    final url = 'https://wa.me/$phoneNumber?text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'CONTACT SUPPORT',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 13,),
        Container(
          width: 460,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00FFFF),
                Color(0xFF00FFFF),
                Color(0xFFFF00FF),
                Color(0xFF0072FF),
                Color(0xFF00FF94),
                Color(0xFF00FF94),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withOpacity(0.98),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Stack(
                  children: [
                    SizedBox(
                      width: Get.width,
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: Image.asset(
                          'assets/bgsupport.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [

                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 76,
                                child: Image.asset('assets/mail.png'),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Need help? Reach out to our support team.",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 37,
                            child: GestureDetector(
                              onTap: _openWhatsApp, // <-- WhatsApp trigger here
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    width: 1,
                                    color: const Color(0xFF00FF94),
                                  ),
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Color(0xFF00FF94),
                                      Color(0xFF00C6FF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: const Text(
                                      "Send Message",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
