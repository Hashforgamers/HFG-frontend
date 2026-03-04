import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

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
        segmentService.onCustomEvent('Campaign Clicked', {
          'campaign_id': 'event_banner_001',
          'placement': 'home_banner',
        });
        fbEventsService.onCampaignClicked(
          campaignId: 'event_banner_001',
          source: 'home_banner',
        );

        Get.snackbar(
          'Event',
          'Event banner clicked!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff00DC00),
          colorText: Colors.white,
        );
      },
      onLongPress: () {
        segmentService.onCustomEvent('Campaign Dismissed', {
          'campaign_id': 'event_banner_001',
        });
        fbEventsService.onCampaignDismissed(campaignId: 'event_banner_001');
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
              child: CachedNetworkImage(
                imageUrl:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075169/bannerBg_fdptob.png',
                height: 160,
                width: double.infinity,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
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
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                        color: const Color(0xff00DC00),
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
              child: CachedNetworkImage(
                imageUrl:
                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075169/bannerHero_yslfl9.png',
                height: 150,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 40)),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
