import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as loc;

import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';

class SearchResult extends StatefulWidget {
  final String? searchQuery;
  final String? location;

  const SearchResult({super.key, this.searchQuery, this.location});

  @override
  State<SearchResult> createState() => _SearchResultState();
}

class _SearchResultState extends State<SearchResult> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final CybercafesController _cafeController;

  // State
  bool _isSearching = false;
  String _currentQuery = '';
  Timer? _debounce;

  // Filters
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Gaming', 'Cafe', 'Nearby', 'Open Now'];

  // Location for distance
  final loc.Location _loc = loc.Location();
  bool _hasLocationPermission = false;
  double? _userLat, _userLng;
  static const _avgCitySpeedKmph = 25;

  // distance cache (id/hash -> km)
  final Map<String, double> _distanceKm = {};

  final List<String> _fallbackImages = const [
    'https://next-level.gg/assets/cafes/11.jpg',
    'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
    'https://media.assettype.com/afkgaming/2024-04/e11d1515-bb0d-48a5-9ad9-1ddfdef286ef/Untitled_design_117_.png',
    'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
    'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _cafeController = Get.put(
      CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
    );

    _searchController.text = widget.searchQuery ?? '';
    _currentQuery = widget.searchQuery ?? '';

    _initLocation();
    _loadCafes(initial: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      if (!mounted) return;
      setState(() {
        _hasLocationPermission = (ld.latitude != null && ld.longitude != null);
        _userLat = ld.latitude;
        _userLng = ld.longitude;
      });
    } catch (_) {
      // ignore and proceed without distances
    }
  }

  Future<void> _loadCafes({bool initial = false}) async {
    setState(() => _isSearching = true);

    try {
      // If you have a server-side search endpoint, call it here with _currentQuery
      // await _cafeController.searchCybercafes(query: _currentQuery);
      // else:
      await _cafeController.fetchCybercafes();
    } finally {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  // ───────────────────────────────── helpers ─────────────────────────────────

  double? _toDouble(dynamic v) => double.tryParse('$v');

  (double?, double?) _cafeLatLng(Map<String, dynamic> cafe) {
    final addr = (cafe['address'] ?? cafe['location'] ?? {}) as Map?;
    if (addr == null) return (null, null);
    return (_toDouble(addr['latitude']), _toDouble(addr['longitude']));
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

  String _formatTimeForDisplay(String timeStr) {
    try {
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

  String _safeAddress(Map<String, dynamic> cafe) {
    // 1) location.address (string)
    final locMap = cafe['location'];
    if (locMap is Map && locMap['address'] is String) {
      return locMap['address'];
    }
    // 2) address { addressLine1, addressLine2, city, state, pincode }
    final addrMap = cafe['address'];
    if (addrMap is Map) {
      final line1 = (addrMap['addressLine1'] ?? '').toString();
      final line2 = (addrMap['addressLine2'] ?? '').toString();
      final city = (addrMap['city'] ?? '').toString();
      final state = (addrMap['state'] ?? '').toString();
      final pin = (addrMap['pincode'] ?? '').toString();
      final parts = [line1, line2, city, state, pin]
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    // 3) direct string
    if (addrMap is String && addrMap.isNotEmpty) return addrMap;
    return 'Address not available';
  }

  String _pickImage(Map<String, dynamic> cafe, int index) {
    final cover = cafe['cover'];
    if (cover is String && cover.isNotEmpty) return cover;
    final imgs = cafe['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map && first['url'] is String && first['url'].toString().isNotEmpty) {
        return first['url'];
      }
      if (first is String && first.isNotEmpty) return first;
    } else if (imgs is String && imgs.isNotEmpty) {
      return imgs;
    }
    return _fallbackImages[index % _fallbackImages.length];
  }

  List<String> _features(Map<String, dynamic> cafe) {
    final f = <String>[];
    final games = cafe['games'];
    if (games is List) {
      for (final g in games.take(3)) {
        if (g != null) f.add(g.toString());
      }
    }
    final amenities = cafe['amenities'];
    if (amenities is List) {
      for (final a in amenities.take(2)) {
        if (a != null) f.add(a.toString());
      }
    }
    if (f.isEmpty) f.addAll(['Gaming PCs', 'High-speed Internet', 'Gaming Setup']);
    return f;
  }

  // Distance + ETA (cached)
  (String dist, String? eta) _distanceLabel(Map<String, dynamic> cafe) {
    final (lat, lng) = _cafeLatLng(cafe);
    if (_userLat == null || _userLng == null || lat == null || lng == null) {
      return ('-- km', null);
    }
    final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    final km = _distanceKm.putIfAbsent(key, () => _haversineKm(_userLat!, _userLng!, lat, lng));
    final etaMin = (_avgCitySpeedKmph > 0) ? (km / _avgCitySpeedKmph * 60).round() : null;
    return ('${km.toStringAsFixed(1)} km', etaMin != null ? '~$etaMin min' : null);
  }

  // ────────────────────────────── derived results ─────────────────────────────

  List<Map<String, dynamic>> get _filteredResults {
    List<Map<String, dynamic>> results =
    _cafeController.cybercafes.cast<Map<String, dynamic>>();

    // search client-side (name/address)
    if (_currentQuery.isNotEmpty) {
      final q = _currentQuery.toLowerCase();
      results = results.where((cafe) {
        final name = (cafe['cafe_name'] ?? '').toString().toLowerCase();
        final addr = _safeAddress(cafe).toLowerCase();
        return name.contains(q) || addr.contains(q);
      }).toList();
    }

    // filter by category
    if (_selectedFilter != 'All') {
      results = results.where((cafe) {
        switch (_selectedFilter) {
          case 'Gaming':
            return cafe['type'] == 'gaming' ||
                (cafe['cafe_name']?.toString().toLowerCase().contains('gaming') ?? false);
          case 'Cafe':
            return cafe['type'] == 'cafe' ||
                (cafe['cafe_name']?.toString().toLowerCase().contains('cafe') ?? false);
          case 'Open Now':
            return _isShopOpen(cafe);
          case 'Nearby':
          // keep all for now; we will sort by distance below
            return true;
        }
        return true;
      }).toList();
    }

    // sort by distance if Nearby (requires user location)
    if (_selectedFilter == 'Nearby' && _hasLocationPermission) {
      results.sort((a, b) {
        final (la, loa) = _cafeLatLng(a);
        final (lb, lob) = _cafeLatLng(b);
        if (la == null || loa == null) return 1;
        if (lb == null || lob == null) return -1;
        final da = _haversineKm(_userLat!, _userLng!, la, loa);
        final db = _haversineKm(_userLat!, _userLng!, lb, lob);
        return da.compareTo(db);
      });
    }

    return results;
  }

  // ───────────────────────────────── UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                onRefresh: () => _loadCafes(),
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Results',
                    style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                if (widget.location != null)
                  Text(widget.location!,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xff338125).withOpacity(.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xff338125)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: const Color(0xff338125),
                    decoration: InputDecoration(
                      hintText: 'Search gaming centers, cafes...',
                      hintStyle: GoogleFonts.inter(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 250), () {
                        if (!mounted) return;
                        setState(() => _currentQuery = value);
                        // If server-side search available, call _loadCafes();
                      });
                    },
                    onSubmitted: (_) => _loadCafes(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _currentQuery = '';
                        _selectedFilter = 'All';
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 37,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xff338125) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xff338125) : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    return Obx(() {
      if (_cafeController.isLoading.value || _isSearching) {
        return const Center(child: RainbowGlowingLoader(size: 50));
      }

      final items = _filteredResults;
      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => RepaintBoundary(
          child: _buildResultCard(items[index], index),
        ),
      );
    });
  }

  Widget _buildResultCard(Map<String, dynamic> cafe, int index) {
    final isOpen = _isShopOpen(cafe);
    final imageUrl = _pickImage(cafe, index);
    final address = _safeAddress(cafe);
    final feats = _features(cafe);
    final (dist, eta) = _distanceLabel(cafe);
    final rating = 4.5; // TODO: plug real rating when API provides
    final price = '₹200/hour'; // TODO: plug real price when API provides

    final width = MediaQuery.of(context).size.width - 32;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final memW = (width * dpr).round();
    const imgH = 200.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                SizedBox(
                  height: imgH,
                  width: double.infinity,
                  child: imageUrl.isEmpty
                      ? Container(color: const Color(0xFF1A1A1A))
                      : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: memW,
                    memCacheHeight: (imgH * dpr).round(),
                    placeholder: (_, __) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: RainbowGlowingLoader(size: 32)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white54, size: 50),
                    ),
                  ),
                ),
                // Status
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen ? const Color(0xff338125) : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Type
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (cafe['type'] ?? 'Gaming').toString(),
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (cafe['cafe_name'] ?? 'Unknown Cafe').toString(),
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('$rating',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // address + distance
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Text(
                        eta == null ? dist : '$dist • $eta',
                        style: GoogleFonts.inter(
                            color: const Color(0xff338125), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // features
    buildFeatureChips(feats),

    const SizedBox(height: 16),

                  // price + action
                  Row(
                    children: [
                      // Text(price,
                      //     style: GoogleFonts.inter(
                      //         fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xff338125))),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: isOpen
                            ? () {
                          final images = cafe['images'];
                          List<dynamic> imagesList = [];
                          if (images is List) {
                            imagesList = images;
                          } else if (images is String && images.isNotEmpty) {
                            imagesList = [{'url': images}];
                          }
                          if (imagesList.isEmpty) {
                            imagesList = [{'url': _pickImage(cafe, index)}];
                          }

                          final featsAll = _features(cafe);

                          Get.to(() => ArenaDetailView(
                            images: imagesList,
                            title: (cafe['cafe_name'] ?? 'Unknown Cafe').toString(),
                            address: address,
                            openingHours: '9 AM - 12 AM', // TODO: plug real hours
                            availableGames: featsAll,
                            amenities: featsAll,
                            phone: (cafe['phone'] ?? cafe['contact_number'] ?? 'Phone not available').toString(),
                            email: (cafe['email'] ?? 'Email not available').toString(),
                            ownerName: (cafe['owner_name'] ?? 'Owner not available').toString(),
                            reviews: const ['Great place!', 'Loved it!'],
                            vendorId: cafe['vendor_id'],
                          ));
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff338125),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(isOpen ? 'View Details' : 'Closed',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 64, color: Colors.white54),
          ),
          const SizedBox(height: 24),
          Text('No cafes found',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentQuery = '';
                _selectedFilter = 'All';
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff338125),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
            ),
            child: Text('Clear Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
// Drop-in: replace your Wrap with this builder
Widget buildFeatureChips(List<String> feats, {int maxToShow = 5}) {
  // 1) Clean + de-dup + cap
  final cleaned = feats
      .map((f) => f.toString().replaceAll(RegExp(r'[{}]'), '').trim())
      .where((f) => f.isNotEmpty)
      .toSet()
      .toList();
  final visible = cleaned.take(maxToShow).toList();
  final remaining = cleaned.length - visible.length;

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final f in visible) _FeaturePill(label: f),
      if (remaining > 0) _MorePill(count: remaining),
    ],
  );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // soft green tint with subtle depth
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF338125).withOpacity(.22),
            const Color(0xFF1A1A1A).withOpacity(.22),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF338125).withOpacity(.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF338125).withOpacity(.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 14, color: const Color(0xFF7FF16A)),
          const SizedBox(width: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7FF16A),
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }

  // very small keyword → icon map; extend as you like
  IconData _iconFor(String s) {
    final t = s.toLowerCase();
    if (t.contains('pc')) return Icons.computer_rounded;
    if (t.contains('ps') || t.contains('playstation')) return Icons.sports_esports_rounded;
    if (t.contains('xbox')) return Icons.sports_esports_rounded;
    if (t.contains('vr')) return Icons.vrpano_rounded;
    if (t.contains('wifi') || t.contains('internet')) return Icons.wifi_rounded;
    if (t.contains('snack') || t.contains('food')) return Icons.fastfood_rounded;
    if (t.contains('ac') || t.contains('air')) return Icons.ac_unit_rounded;
    if (t.contains('tournament') || t.contains('event')) return Icons.emoji_events_rounded;
    if (t.contains('console')) return Icons.sports_esports_rounded;
    return Icons.label_rounded;
  }
}

class _MorePill extends StatelessWidget {
  const _MorePill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Text(
        '+$count more',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}
