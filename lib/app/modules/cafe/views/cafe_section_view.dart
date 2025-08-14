import 'dart:math' as math;
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
import 'package:location/location.dart' as loc;
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
  final loc.Location _loc = loc.Location();
  double? _userLat, _userLng;
  bool _hasLocationPermission = false;
  static const _avgCitySpeedKmph = 25; // for ETA calc

  String selectedLabel = '';
  final List<String> labels = [
    'Location',
    'Price Range',
    'Distance',
    'Favorites',
  ];

  @override
  void initState() {
    super.initState();
    widget._cafeController.fetchCybercafes();
    _initLocation();

    // Track cafe list viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.segmentService.onCafeListViewed(
        sortType: 'distance',
        filterType: 'all',
      );
    });
  }
  Future<void> _initLocation() async {
    try {
      bool service = await _loc.serviceEnabled();
      if (!service) service = await _loc.requestService();
      if (!service) return;

      var perm = await _loc.hasPermission();
      if (perm == loc.PermissionStatus.denied) {
        perm = await _loc.requestPermission();
      }
      if (perm != loc.PermissionStatus.granted && perm != loc.PermissionStatus.grantedLimited) {
        return;
      }

      final ld = await _loc.getLocation();
      final lat = ld.latitude, lng = ld.longitude;
      if (lat == null || lng == null) return;

      if (!mounted) return;
      setState(() {
        _hasLocationPermission = true;
        _userLat = lat;
        _userLng = lng;
      });
    } catch (_) {/* ignore */}
  }
  double? _toDouble(dynamic v) => double.tryParse('$v');

  double? _cafeLat(Map<String, dynamic> cafe) {
    final addr = cafe['address'] ?? cafe['location'] ?? {};
    return _toDouble(addr['latitude']);
  }
  double? _cafeLng(Map<String, dynamic> cafe) {
    final addr = cafe['address'] ?? cafe['location'] ?? {};
    return _toDouble(addr['longitude']);
  }

// Haversine distance in KM
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
  double _deg2rad(double d) => d * math.pi / 180.0;

// ── Opening hours / Open-Closed
  String _formatTimeForDisplay(String timeStr) {
    try {
      // handle "09:00:00", "9:00", "9:00 AM"
      final t = timeStr.trim();
      if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
        final parts = t.split(RegExp(r'\s+'));
        final time = parts.first;
        final period = parts.last.toUpperCase();
        final tp = time.split(':');
        var h = int.parse(tp[0]);
        final m = tp.length > 1 ? int.parse(tp[1]) : 0;
        if (period == 'PM' && h != 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      }
      // remove seconds "HH:mm:ss" → "HH:mm"
      final p = t.split(':');
      if (p.length >= 2) return '${p[0]}:${p[1]}';
      return t;
    } catch (_) { return timeStr; }
  }

  int? _parseMinutesSinceMidnight(String timeStr) {
    try {
      final t = _formatTimeForDisplay(timeStr);
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return h * 60 + m;
    } catch (_) { return null; }
  }

  bool _isCurrentlyOpen(Map<String, dynamic> cafe) {
    final open = cafe['opening_time']?.toString() ?? '';
    final close = cafe['closing_time']?.toString() ?? '';
    if (open.isEmpty || close.isEmpty) return false;
    final o = _parseMinutesSinceMidnight(open);
    final c = _parseMinutesSinceMidnight(close);
    if (o == null || c == null) return false;

    final now = DateTime.now();
    final cur = now.hour * 60 + now.minute;

    if (c < o) {
      // e.g. 23:00–02:00
      return cur >= o || cur <= c;
    }
    return cur >= o && cur <= c;
  }

  bool _isShopOpen(Map<String, dynamic> cafe) {
    final shopOpen = cafe['shop_open'];
    if (shopOpen != null) {
      if (shopOpen is bool) return shopOpen;
      if (shopOpen is String) return shopOpen.toLowerCase() == 'true';
      if (shopOpen is num) return shopOpen == 1;
    }
    final status = cafe['status']?.toString().toLowerCase();
    if (status != null) {
      if (status == 'active' || status == 'verified' || status == 'open' || status == 'operational') {
        return true;
      }
      if (status == 'pending_verification') {
        return _isCurrentlyOpen(cafe);
      }
    }
    final isOpen = cafe['is_open'];
    if (isOpen != null) {
      if (isOpen is bool) return isOpen;
      if (isOpen is String) return isOpen.toLowerCase() == 'true';
      if (isOpen is num) return isOpen == 1;
    }
    return _isCurrentlyOpen(cafe);
  }

  String _openCloseLabel(Map<String, dynamic> cafe) {
    final openNow = _isShopOpen(cafe);
    final opening = cafe['opening_time']?.toString() ?? '';
    final closing = cafe['closing_time']?.toString() ?? '';
    final hasHours = opening.isNotEmpty && closing.isNotEmpty;
    final openDisp = hasHours ? _formatTimeForDisplay(opening) : '';
    final closeDisp = hasHours ? _formatTimeForDisplay(closing) : '';

    if (openNow) {
      return hasHours ? closeDisp : 'Open';
    } else {
      return hasHours ? openDisp : 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 5),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: labels.map((label) {
        //     return _buildCafeContainer(
        //       label: label,
        //       isSelected: selectedLabel == label,
        //       screenWidth: screenWidth,
        //     );
        //   }).toList(),
        // ),
        // const SizedBox(height: 20),
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
                final images = cafe['images'];
                String imageUrl = 'https://next-level.gg/assets/cafes/11.jpg'; // Fallback image
                
                if (images != null) {
                  if (images is List && images.isNotEmpty) {
                    // If images is a list, get the first image URL
                    final firstImage = images[0];
                    if (firstImage is Map && firstImage['url'] != null && firstImage['url'].toString().isNotEmpty) {
                      imageUrl = firstImage['url'];
                    }
                  } else if (images is String && images.isNotEmpty) {
                    // If images is a string (URL), use it directly
                    imageUrl = images;
                  }
                }
                
                // Additional fallback check - if the URL is empty or invalid, use default
                if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
                  imageUrl = 'https://next-level.gg/assets/cafes/11.jpg';
                }
                final isOpen = _isShopOpen(cafe);
                final openLabel = _openCloseLabel(cafe);

// Distance + ETA
                double? km;
                int? etaMin;
                final clat = _cafeLat(cafe);
                final clng = _cafeLng(cafe);
                if (_userLat != null && _userLng != null && clat != null && clng != null) {
                  km = _haversineKm(_userLat!, _userLng!, clat, clng);
                  etaMin = (_avgCitySpeedKmph > 0) ? (km / _avgCitySpeedKmph * 60).round() : null;
                }                return GestureDetector(
                  onTap: () {
                    // Track gaming cafe viewed event
                    final cafeId = cafe['vendor_id']?.toString() ?? '';
                    final location = cafe['location']?['address'] ?? 'Unknown';
                    
                    // Handle availableGames field safely
                    List<String> availableGames = ['Unknown'];
                    final games = cafe['games'];
                    if (games != null) {
                      if (games is List) {
                        availableGames = games.map((game) => game.toString()).toList();
                      } else if (games is String) {
                        availableGames = [games];
                      }
                    }

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

                    // Prepare images list for ArenaDetailView
                    List<dynamic> imagesList = [];
                    if (images != null) {
                      if (images is List && images.isNotEmpty) {
                        imagesList = images;
                      } else if (images is String && images.isNotEmpty) {
                        // If images is a string, create a list with one item
                        imagesList = [{'url': images}];
                      }
                    }
                    
                    // Ensure we always have at least one fallback image
                    if (imagesList.isEmpty) {
                      imagesList = [{'url': 'https://next-level.gg/assets/cafes/11.jpg'}];
                    }
                    
                    Get.to(
                      () => ArenaDetailView(
                        images: imagesList,
                        title: cafe['cafe_name'] ?? 'Unknown Cafe',
                        address:
                            cafe['location']?['address'] ??
                            'Address not available',
                        openingHours: '9 AM - 12 AM',
                        availableGames: availableGames,
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
                            placeholder: (_, _) => Container(
                              color: const Color(0xff1a1a1a),
                              child: const Center(
                                child: RainbowGlowingLoader(size: 40),
                              ),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xff1a1a1a),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cafe Image',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                                        CachedNetworkImage(
                                          imageUrl:
                                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-02_hvvehr.png',
                                          height: 16,
                                          width: 16,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => const Center(
                                            child: RainbowGlowingLoader(
                                              size: 4,
                                            ),
                                          ),
                                          errorWidget: (_, _, _) => const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Consoles',
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

                                        const SizedBox(width: 8),
                                        Text(
                                          km == null ? '-- km' : '${km.toStringAsFixed(1)} km${etaMin != null ? ' • ~${etaMin} min' : ''}',
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
                                          icon:
                                              "https://res.cloudinary.com/dxjjigepf/image/upload/v1755075082/ps_krf4kw.png",
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPlatformIcon(
                                          icon:
                                              "https://res.cloudinary.com/dxjjigepf/image/upload/v1755075086/xbox_fmz0bn.png",
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPlatformIcon(
                                          icon:
                                              "https://res.cloudinary.com/dxjjigepf/image/upload/v1755075080/pc_ah5ulv.png",
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
    return CachedNetworkImage(
      imageUrl: icon,
      height: 18,
      width: 18,
      placeholder: (_, _) =>
          const Center(child: RainbowGlowingLoader(size: 10)),
      errorWidget: (_, _, _) => const Icon(Icons.error, color: Colors.red),
    );
  }
}
