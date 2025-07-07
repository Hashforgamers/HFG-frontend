import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:shimmer/shimmer.dart';

class CafeSection extends StatelessWidget {
  final CybercafesController _cafeController =
  Get.put(CybercafesController(remoteRepo: locator<RemoteRepoInterface>()));

  CafeSection({super.key}) {
    _cafeController.fetchCybercafes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Cafes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Obx(() {
          if (_cafeController.isLoading.value) {
            return SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
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


          if (_cafeController.cybercafes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No cafes available nearby.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            );
          }

          return SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 15),
              itemCount: _cafeController.cybercafes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cafe = _cafeController.cybercafes[index];
                final imageUrl = cafe['cover'] ??
                    'https://next-level.gg/assets/cafes/11.jpg'; // Fallback
                final isOpen = cafe['status'] == 'active';

                return GestureDetector(
                  onTap: () => Get.to(
                        () => ArenaDetailView(
                      images: imageUrl,
                      title: cafe['cafe_name'] ?? 'Unknown Cafe',
                      address: cafe['location']?['address'] ??
                          'Address not available',
                      openingHours: '9 AM - 12 AM',
                      availableGames: const ['Game 1', 'Game 2'],
                      amenities: const ['Amenity 1', 'Amenity 2'],
                      phone: cafe['phone'] ?? cafe['contact_number'] ?? 'Phone not available',
                      email: cafe['email'] ?? 'Email not available',
                      ownerName: cafe['owner_name'] ?? 'Owner not available',
                      reviews: const ['Great place!', 'Loved it!'],
                      vendorId: cafe['vendor_id'],
                    ),
                  ),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),

                      color: const Color(0xff0E0E0E),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.6),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        /// Café image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: 300,
                            height: 250,
                            placeholder: (_, __) =>
                            const Center(child: RainbowGlowingLoader(size: 40)),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white54, size: 40),
                            ),
                          ),
                        ),

                        /// Frosted footer with info
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.0),
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cafe['cafe_name'] ?? 'Unknown Cafe',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cafe['location']?['address'] ??
                                          'Address not available',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.circle,
                                            size: 8,
                                            color: isOpen
                                                ? Colors.greenAccent
                                                : Colors.redAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOpen ? 'Open' : 'Closed',
                                          style: TextStyle(
                                              color: isOpen
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent,
                                              fontSize: 12),
                                        ),
                                        const Spacer(),
                                        const Text('2.3 km',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    )
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
}