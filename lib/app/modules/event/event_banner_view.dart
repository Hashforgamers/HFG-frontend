import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
import 'package:cached_network_image/cached_network_image.dart';
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
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF338125), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '🎮 Special Gaming Event!',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
