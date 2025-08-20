import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Onboarding content
          IntroductionScreen(
            globalBackgroundColor: Colors.black,
            showSkipButton: false, // hide built-in skip
            pages: [
              PageViewModel(useScrollView: false,
                titleWidget: const SizedBox.shrink(),
                bodyWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),

                    Image.asset("assets/onboarding_icons/image 180.png",
                        height: 250),
                    const SizedBox(height: 50),
                    Text("Book a slot",
                        style: GoogleFonts.orbitron(
                            color: const Color(0xff6DFB60),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text("at your Favourite\nGaming Cafe",
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        "Enjoy immersive gaming, fast PCs, comfortable seating, friendly vibes, and endless fun with friends.",
                        style: GoogleFonts.orbitron(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              PageViewModel(useScrollView: false,
                titleWidget: const SizedBox.shrink(),
                bodyWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ const SizedBox(height: 100),
                    Image.asset("assets/onboarding_icons/image 181.png",
                        height: 250),
                    const SizedBox(height: 50),
                    Text("Refer & Earn",
                        style: GoogleFonts.orbitron(
                            color: const Color(0xff6DFB60),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text("Hash Coins",
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        "Share with friends, grow your community, unlock exclusive rewards, play more, save more, and enjoy ultimate gaming benefits.",
                        style: GoogleFonts.orbitron(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              PageViewModel(useScrollView: false,
                titleWidget: const SizedBox.shrink(),
                bodyWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 100),
                    Image.asset("assets/onboarding_icons/image 182.png",
                        height: 250),
                    const SizedBox(height: 50),
                    Text("Participate",
                        style: GoogleFonts.orbitron(
                            color: const Color(0xff6DFB60),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text("in Sick Tournaments",
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        "Compete with top gamers, win epic prizes, earn glory, and become a legend in gaming.",
                        style: GoogleFonts.orbitron(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],

            // Bottom controls
            next: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color:Color(0xffB6B6B6) )
                
              ),
              child: Container(margin: EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffB6B6B6),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.chevron_right, color: Colors.black),
              ),
            ),
            done: Text("Letsgo",
                style: GoogleFonts.orbitron(
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            onDone: () {
              Navigator.pushReplacementNamed(context, "/login");
            },

            dotsDecorator: DotsDecorator(
              color: Colors.white30,

              activeColor: Colors.grey,
              size: const Size.square(8.0),
              activeSize: const Size(42.0, 4.0), // elongated active dot
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),

          // Custom Skip at top-right
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, "/login"),
              child: Text("Skip",
                  style: GoogleFonts.orbitron(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
