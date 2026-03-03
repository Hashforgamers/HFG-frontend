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
import 'package:url_launcher/url_launcher.dart';

import '../../../../utils/service.dart';
import '../../../../utils/widgets/bounce_tap_widget.dart';

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
  static const String _sheetUrl =
      "https://docs.google.com/forms/d/1WnnEsOkza8ois79Gvp9iGvPAemq1Oi3YPHFlohfKlxM/edit";
  bool _hasFetchedCafes = false;

  void _openSheetInBrowser() async {
    final uri = Uri.parse(_sheetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Link', 'Could not open browser');
    }
  }

  Future<void> _chooseOpenSheet() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser, color: Colors.white),
              title: Text(
                'Open in browser',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 1),
            ),
            // ListTile(
            //   leading: const Icon(Icons.web, color: Colors.white),
            //   title: Text('Open inside app (WebView)', style: GoogleFonts.inter(color: Colors.white)),
            //   onTap: () => Navigator.pop(context, 2),
            // ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == 1) _openSheetInBrowser();
  }

  final loc.Location _loc = loc.Location();
  double? _userLat, _userLng;
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
    if (!_hasFetchedCafes) {
      widget._cafeController.fetchCybercafes();
      _hasFetchedCafes = true;
    }
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
      if (perm != loc.PermissionStatus.granted &&
          perm != loc.PermissionStatus.grantedLimited) {
        return;
      }

      final ld = await _loc.getLocation();
      final lat = ld.latitude, lng = ld.longitude;
      if (lat == null || lng == null) return;

      if (!mounted) return;
      setState(() {
        _userLat = lat;
        _userLng = lng;
      });
    } catch (_) {
      /* ignore */
    }
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
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
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
    } catch (_) {
      return timeStr;
    }
  }

  int? _parseMinutesSinceMidnight(String timeStr) {
    try {
      final t = _formatTimeForDisplay(timeStr);
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return h * 60 + m;
    } catch (_) {
      return null;
    }
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
      if (status == 'active' ||
          status == 'verified' ||
          status == 'open' ||
          status == 'operational') {
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

  List<Map<String, dynamic>> _sortedCafesByNearest(List<dynamic> raw) {
    final cafes = raw.cast<Map<String, dynamic>>().toList();
    if (_userLat == null || _userLng == null) return cafes;

    cafes.sort((a, b) {
      final aLat = _cafeLat(a);
      final aLng = _cafeLng(a);
      final bLat = _cafeLat(b);
      final bLng = _cafeLng(b);

      final aDist = (aLat == null || aLng == null)
          ? double.infinity
          : _haversineKm(_userLat!, _userLng!, aLat, aLng);
      final bDist = (bLat == null || bLng == null)
          ? double.infinity
          : _haversineKm(_userLat!, _userLng!, bLat, bLng);
      return aDist.compareTo(bDist);
    });

    return cafes;
  }

  double? _nearestDistanceKm(List<Map<String, dynamic>> cafes) {
    if (_userLat == null || _userLng == null || cafes.isEmpty) return null;
    final first = cafes.first;
    final lat = _cafeLat(first);
    final lng = _cafeLng(first);
    if (lat == null || lng == null) return null;
    return _haversineKm(_userLat!, _userLng!, lat, lng);
  }

  Widget _comingSoonNearYouBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xffFF8A1F).withValues(alpha: 0.14),
        border: Border.all(color: const Color(0xffFF8A1F).withValues(alpha: 0.45)),
      ),
      child: Text(
        'Coming Soon Near You',
        style: GoogleFonts.inter(
          color: const Color(0xffFFAE5C),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Text(
              'BROWSE CAFES',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            BounceTap(
              onTap: _chooseOpenSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'List Your Cafe',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff00DC00),
                      ),
                    ),
                    const Icon(Icons.arrow_right_outlined),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          final sortedCafes = _sortedCafesByNearest(
            widget._cafeController.cybercafes,
          );
          final nearestKm = _nearestDistanceKm(sortedCafes);
          final showComingSoon = nearestKm != null && nearestKm > 20;
          final double cardWidth = MediaQuery.of(context).size.width - 30;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showComingSoon) _comingSoonNearYouBanner(),
              SizedBox(
                height: 230,
                width: MediaQuery.of(context).size.width,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: sortedCafes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (context, index) {
                    final cafe = sortedCafes[index];
                final images = cafe['images'];
                String imageUrl =
                    'https://next-level.gg/assets/cafes/11.jpg'; // Fallback image

                if (images != null) {
                  if (images is List && images.isNotEmpty) {
                    // If images is a list, get the first image URL
                    final firstImage = images[0];
                    if (firstImage is Map &&
                        firstImage['url'] != null &&
                        firstImage['url'].toString().isNotEmpty) {
                      imageUrl = firstImage['url'];
                    }
                  } else if (images is String && images.isNotEmpty) {
                    // If images is a string (URL), use it directly
                    imageUrl = images;
                  }
                }

                // Additional fallback check - if the URL is empty or invalid, use default
                if (imageUrl.isEmpty ||
                    imageUrl == 'null' ||
                    imageUrl == 'undefined') {
                  imageUrl = 'https://next-level.gg/assets/cafes/11.jpg';
                }
                final isOpen = _isShopOpen(cafe);

                // Distance + ETA
                double? km;
                int? etaMin;
                final clat = _cafeLat(cafe);
                final clng = _cafeLng(cafe);
                if (_userLat != null &&
                    _userLng != null &&
                    clat != null &&
                    clng != null) {
                  km = _haversineKm(_userLat!, _userLng!, clat, clng);
                  etaMin = (_avgCitySpeedKmph > 0)
                      ? (km / _avgCitySpeedKmph * 60).round()
                      : null;
                }
                void openCafeDetails() {
                    // Track gaming cafe viewed event
                    final cafeId = cafe['vendor_id']?.toString() ?? '';
                    final cafeName =
                        cafe['cafe_name']?.toString() ?? 'Unknown Cafe';
                    final location = cafe['location']?['address'] ?? 'Unknown';
                    final email = cafe['email'] ?? 'Email not available';

                    // Handle availableGames field safely
                    List<String> availableGames = ['Unknown'];
                    final games = cafe['games'];
                    if (games != null) {
                      if (games is List) {
                        availableGames = games
                            .map((game) => game.toString())
                            .toList();
                      } else if (games is String) {
                        availableGames = [games];
                      }
                    }

                    widget.segmentService.onGamingCafeViewed(
                      cafeId: cafeId,
                      cafeName: cafeName,
                      location: location,
                      availableGames: availableGames,
                      email: email,
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
                        imagesList = [
                          {'url': images},
                        ];
                      }
                    }

                    // Ensure we always have at least one fallback image
                    if (imagesList.isEmpty) {
                      imagesList = [
                        {'url': 'https://next-level.gg/assets/cafes/11.jpg'},
                      ];
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
                        amenities: cafe["amenities"] ?? [''],
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
                }

                return BounceTap(
                  onTap: openCafeDetails,
                  child: Container(
                    width: cardWidth,
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
                            width: cardWidth,
                            height: 250,
                            placeholder: (_, __) => Container(
                              color: const Color(0xff1a1a1a),
                              child: const Center(
                                child: RainbowGlowingLoader(size: 40),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xff1a1a1a),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
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
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Header row: Name + Console
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: isOpen
                                              ? const Color(0xff00DC00)
                                              : Colors.redAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            toStartCase(
                                              cafe['cafe_name']?.toString() ??
                                                  'Unknown Cafe',
                                            ),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        CachedNetworkImage(
                                          imageUrl:
                                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-02_hvvehr.png',
                                          height: 16,
                                          width: 16,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: RainbowGlowingLoader(
                                              size: 4,
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
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

                                    /// Distance + Time + Platform Icons
                                    Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        Text(
                                          km == null
                                              ? '-- km'
                                              : '${km.toStringAsFixed(1)} km${etaMin != null ? ' • ~${etaMin} min' : ''}',
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
                                    if (index == 0) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xff00DC00,
                                            ).withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Filling Fast',
                                            style: GoogleFonts.inter(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: OutlinedButton(
                                        onPressed: openCafeDetails,
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff00DC00,
                                          ).withValues(alpha: 0.22),
                                          foregroundColor: const Color(
                                            0xff00DC00,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xff00DC00),
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Book Now',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFF8A1F).withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '₹30 Credit',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                  },
                ),
              ),
            ],
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
