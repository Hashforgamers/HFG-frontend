import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class InviteCafeView extends StatefulWidget {
  const InviteCafeView({super.key});

  @override
  State<InviteCafeView> createState() => _InviteCafeViewState();
}

class _InviteCafeViewState extends State<InviteCafeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF808080),
                    size: 30,
                  ),
                  hintText: 'Search by game, location or café name',
                  hintStyle: GoogleFonts.inter(
                    color: Color(0xFF808080),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: '',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                        placeholder: (_, _) =>
                            const Center(child: RainbowGlowingLoader(size: 10)),
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.error, color: Colors.red),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Couldn’t find your \nfavorite cafe?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Help grow HashForGamers — \ninvite your local café and bring gaming closer to home!',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xff00DC00),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(-2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CachedNetworkImage(
                            imageUrl: '',
                            height: 40,
                            width: 40,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const Center(
                              child: RainbowGlowingLoader(size: 10),
                            ),
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Invite a cafe →',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Got a café in mind? Send them our way— we\'ll handle the rest!',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
