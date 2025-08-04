import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';

class EventBanner extends StatefulWidget {
  const EventBanner({super.key});

  @override
  State<EventBanner> createState() => _EventBannerState();
}

class _EventBannerState extends State<EventBanner> {
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentService.onCampaignViewed(
        source: 'home_screen',
        campaignId: 'event_banner_001',
      );
      fbEventsService.onCampaignViewed(
        source: 'home_screen',
        campaignId: 'event_banner_001',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        segmentService.onCampaignConversion(
          campaignId: 'event_banner_001',
          action: 'banner_clicked',
        );
        fbEventsService.onCampaignConversion(
          campaignId: 'event_banner_001',
          action: 'banner_clicked',
        );

        Get.snackbar(
          'Event',
          'Event banner clicked!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/bannerBg.png',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Glass layer
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),

            // Text & Button
            Positioned(
              left: 20,
              top: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Gaming Event',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Win prize upto ₹70,000*',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB6B6B6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF75F94C),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Join Now',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hero image
            Positioned(
              bottom: 0,
              right: 48,
              child: SizedBox(
                height: 150,
                child: Image.asset(
                  "assets/images/bannerHero.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
