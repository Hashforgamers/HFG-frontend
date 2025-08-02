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
    // Track campaign viewed event
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
        // Track campaign conversion event
        segmentService.onCampaignConversion(
          campaignId: 'event_banner_001',
          action: 'banner_clicked',
        );
        fbEventsService.onCampaignConversion(
          campaignId: 'event_banner_001',
          action: 'banner_clicked',
        );

        // Navigate to event details or perform action
        Get.snackbar(
          'Event',
          'Event banner clicked!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/bannerBg.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Gaming Event',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Win prize upto 70,000*',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB6B6B6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF75F94C),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Join Now',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 62,
              child: SizedBox(
                height: 180,
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
