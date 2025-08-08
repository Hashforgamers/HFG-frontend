import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';

class CafeSection extends StatefulWidget {
  CafeSection({super.key});

  final CybercafesController _cafeController = Get.put(
    CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
  );
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  State<CafeSection> createState() => _CafeSectionState();
}

class _CafeSectionState extends State<CafeSection> {
  String selectedLabel = '';
  final List<String> labels = [
    'Location',
    'Price Range',
    'Distance',
    'Favourtites',
  ];

  @override
  void initState() {
    super.initState();
    widget._cafeController.fetchCybercafes();

    // Track cafe list viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.segmentService.onCafeListViewed(
        sortType: 'distance',
        filterType: 'all',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BROWSE CAFES',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((label) {
            return _buildCafeContainer(
              label: label,
              isSelected: selectedLabel == label,
              screenWidth: screenWidth,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (widget._cafeController.isLoading.value) {
            return SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade800,
                    highlightColor: Colors.grey.shade700,
                    child: Container(
                      width: 300,
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade900,
                      ),
                    ),
                  );
                },
              ),
            );
          }

          if (widget._cafeController.cybercafes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No cafes available nearby.',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
            );
          }

          return SizedBox(
            height: 230,
            width: MediaQuery.of(context).size.width,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: widget._cafeController.cybercafes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final cafe = widget._cafeController.cybercafes[index];
                final imageUrl =
                    cafe['cover'] ??
                    'https://next-level.gg/assets/cafes/11.jpg'; // Fallback
                final isOpen = cafe['status'] == 'active';

                return GestureDetector(
                  onTap: () {
                    // Track gaming cafe viewed event
                    final cafeId = cafe['vendor_id']?.toString() ?? '';
                    final location = cafe['location']?['address'] ?? 'Unknown';
                    final availableGames =
                        cafe['games']?.cast<String>() ?? ['Unknown'];

                    widget.segmentService.onGamingCafeViewed(
                      cafeId: cafeId,
                      location: location,
                      availableGames: availableGames,
                    );
                    widget.fbEventsService.onGamingCafeViewed(
                      cafeId: cafeId,
                      location: location,
                      availableGames: availableGames,
                    );

                    Get.to(
                      () => ArenaDetailView(
                        images: imageUrl,
                        title: cafe['cafe_name'] ?? 'Unknown Cafe',
                        address:
                            cafe['location']?['address'] ??
                            'Address not available',
                        openingHours: '9 AM - 12 AM',
                        availableGames: const ['Game 1', 'Game 2'],
                        amenities: const ['Amenity 1', 'Amenity 2'],
                        phone:
                            cafe['phone'] ??
                            cafe['contact_number'] ??
                            'Phone not available',
                        email: cafe['email'] ?? 'Email not available',
                        ownerName: cafe['owner_name'] ?? 'Owner not available',
                        reviews: const ['Great place!', 'Loved it!'],
                        vendorId: cafe['vendor_id'],
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xff0E0E0E),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        /// Café image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width - 30,
                            height: 250,
                            placeholder: (_, __) => const Center(
                              child: RainbowGlowingLoader(size: 40),
                            ),
                            errorWidget: (_, __, ___) => Container(
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

                        /// Frosted footer with info
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: isOpen
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cafe['cafe_name'] ?? 'Unknown Cafe',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Image.asset(
                                          "assets/icons/gaming-pad-02.png",
                                          height: 16,
                                          width: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '7 Slots',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        Row(
                                          children: List.generate(
                                            4,
                                            (index) => const Icon(
                                              Icons.star,
                                              color: Color(0xFFE6D009),
                                              size: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '2.3 km',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 13,
                                        ),
                                        const Spacer(),
                                        _buildPlatformIcon(
                                          icon: "assets/icons/ps.png",
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPlatformIcon(
                                          icon: "assets/icons/xbox.png",
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPlatformIcon(
                                          icon: "assets/icons/pc_1.png",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlatformIcon({required String icon}) {
    return Image.asset(icon, height: 18, width: 18, fit: BoxFit.cover);
  }

  Widget _buildCafeContainer({
    required String label,
    required bool isSelected,
    required double screenWidth,
  }) {
    final totalSpacing = (4 - 1) * 18.0;
    final itemWidth = (screenWidth - totalSpacing) / 4;

    return GestureDetector(
      onTap: () {
        selectedLabel = label;
        setState(() {});
      },
      child: Container(
        height: 40,
        width: itemWidth,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white70,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.black, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
