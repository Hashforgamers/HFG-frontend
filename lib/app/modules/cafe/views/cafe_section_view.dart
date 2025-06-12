import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';

class CafeSection extends StatelessWidget {
  final CybercafesController _cybercafesController = Get.put(CybercafesController(
    remoteRepo: locator<RemoteRepoInterface>(),
  ));

  CafeSection({Key? key}) : super(key: key) {
    _cybercafesController.fetchCybercafes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Nearby Cafes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (_cybercafesController.isLoading.value) {
            return const Center(
              child: RainbowGlowingLoader(size: 50),
            );
          }

          if (_cybercafesController.cybercafes.isEmpty) {
            return const Center(
              child: Text(
                'No cafes available nearby.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _cybercafesController.cybercafes.length,
              itemBuilder: (context, index) {
                final cafe = _cybercafesController.cybercafes[index];
                return GestureDetector(
                  onTap: () => Get.to(() => ArenaDetailView(
                    images: 'https://next-level.gg/assets/cafes/11.jpg',
                    title: cafe['cafe_name'] ?? 'Unknown Cafe',
                    address: cafe['location']?['address'] ?? 'Address not available',
                    openingHours: '9 AM - 12 AM',
                    availableGames: const ['Game 1', 'Game 2'],
                    amenities: const ['Amenity 1', 'Amenity 2'],
                    contactInfo: cafe['contact_number'] ?? 'Contact not available',
                    reviews: const ['Great place!', 'Loved it!'],
                    vendorId: cafe['vendor_id'],
                  )),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xffDE3A3A),
                          Color(0xff8B0000),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cafe['cafe_name'] ?? 'Unknown Cafe',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cafe['location']?['address'] ?? 'Address not available',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: cafe['status'] == 'active'
                                    ? Colors.green
                                    : Colors.red,
                                size: 8,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cafe['status'] == 'active' ? 'Open' : 'Closed',
                                style: TextStyle(
                                  color: cafe['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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