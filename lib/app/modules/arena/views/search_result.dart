import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as loc;

import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/app/modules/arena/utils/arena_games_extractor.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_card.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_empty_state.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_filters.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_header.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_search_bar.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/location_permission_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  late final CybercafesController _cafeController;
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final LocationPermissionService _locationPermissionService =
      locator<LocationPermissionService>();

  // State
  bool _isSearching = false;
  bool _isSearchFocused = false;
  String _currentQuery = '';
  Timer? _debounce;
  Worker? _cafesWorker;
  List<Map<String, dynamic>> _visibleResults = [];

  // Filters
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Gaming', 'Cafe', 'Nearby', 'Open Now'];

  // Location for distance
  late final loc.Location _loc = _locationPermissionService.location;
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
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    _scrollController.addListener(_onScroll);
    _cafesWorker = ever(_cafeController.cybercafes, (_) => _recomputeResults());

    _initLocation();
    _loadCafes(forceRefresh: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final city = (widget.location ?? '').trim();
      unawaited(
        _segmentService.onCustomEvent('Nearby Cafes Viewed', {
          'city': city.isEmpty ? 'unknown' : city,
        }),
      );
      unawaited(
        _fbEventsService.onNearbyCafesViewed(
          city: city.isEmpty ? 'unknown' : city,
        ),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cafesWorker?.dispose();
    _scrollController.removeListener(_onScroll);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final service = await _locationPermissionService.ensureServiceEnabled();
      if (!service) return;

      final perm = await _locationPermissionService.ensurePermission();
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
      _recomputeResults();
    } catch (_) {
      // ignore and proceed without distances
    }
  }

  Future<void> _loadCafes({bool forceRefresh = false}) async {
    setState(() => _isSearching = true);

    try {
      // If you have a server-side search endpoint, call it here with _currentQuery
      // await _cafeController.searchCybercafes(query: _currentQuery);
      // else:
      await _cafeController.fetchCybercafes(forceRefresh: forceRefresh);
      _recomputeResults();
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
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
    final apiFlagKeys = [
      'shop_open',
      'is_open',
      'isOpen',
      'open_close_flag',
      'currently_open',
      'is_available',
    ];
    for (final key in apiFlagKeys) {
      final parsed = _parseApiBool(cafe[key]);
      if (parsed != null) {
        return parsed;
      }
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
      if (status == 'closed' || status == 'inactive') {
        return false;
      }
    }

    return _isCurrentlyOpen(cafe);
  }

  bool? _parseApiBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'open') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'closed') {
        return false;
      }
    }
    return null;
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
      final parts = [
        line1,
        line2,
        city,
        state,
        pin,
      ].where((e) => e.isNotEmpty).toList();
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
      if (first is Map &&
          first['url'] is String &&
          first['url'].toString().isNotEmpty) {
        return first['url'];
      }
      if (first is String && first.isNotEmpty) return first;
    } else if (imgs is String && imgs.isNotEmpty) {
      return imgs;
    }
    return _fallbackImages[index % _fallbackImages.length];
  }

  String _normalizeFeatureLabel(dynamic value) {
    var raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    raw = raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    if (raw.isEmpty) return '';
    return raw
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  List<String> _extractFeatureValues(dynamic source) {
    final values = <String>[];
    if (source == null) return values;

    if (source is String) {
      final parts = source.split(RegExp(r'[,|/]'));
      for (final part in parts) {
        final label = _normalizeFeatureLabel(part);
        if (label.isNotEmpty) values.add(label);
      }
      return values;
    }

    if (source is List) {
      for (final item in source) {
        values.addAll(_extractFeatureValues(item));
      }
      return values;
    }

    if (source is Map) {
      final candidateKeys = [
        'name',
        'title',
        'facility',
        'feature',
        'amenity',
        'label',
        'value',
      ];
      for (final key in candidateKeys) {
        final v = source[key];
        if (v == null) continue;
        values.addAll(_extractFeatureValues(v));
      }
      if (values.isEmpty) {
        for (final v in source.values) {
          values.addAll(_extractFeatureValues(v));
        }
      }
      return values;
    }

    final label = _normalizeFeatureLabel(source);
    if (label.isNotEmpty) values.add(label);
    return values;
  }

  List<String> _features(Map<String, dynamic> cafe) {
    final normalized = <String>[];
    final seen = <String>{};

    void addFrom(dynamic source, {int? limit}) {
      if (source == null) return;
      for (final item in _extractFeatureValues(source)) {
        final clean = item.trim();
        if (clean.isEmpty) continue;
        final key = clean.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        normalized.add(clean);
        if (limit != null && normalized.length >= limit) return;
      }
    }

    addFrom(cafe['facilities'], limit: 6);
    addFrom(cafe['features'], limit: 6);
    addFrom(cafe['amenities'], limit: 6);
    addFrom(cafe['services'], limit: 6);
    addFrom(cafe['tags'], limit: 6);

    final details = cafe['vendor_details'];
    if (details is Map) {
      addFrom(details['facilities'], limit: 6);
      addFrom(details['features'], limit: 6);
      addFrom(details['amenities'], limit: 6);
    }

    final profile = cafe['profile'];
    if (profile is Map) {
      addFrom(profile['facilities'], limit: 6);
      addFrom(profile['features'], limit: 6);
      addFrom(profile['amenities'], limit: 6);
    }

    addFrom(cafe['games'], limit: 6);

    if (normalized.isEmpty) {
      normalized.addAll(['Gaming PCs', 'High-Speed Internet', 'Gaming Setup']);
    }
    return normalized.take(6).toList();
  }

  List<String> _resultHighlights(Map<String, dynamic> cafe) {
    final availableGames = extractArenaAvailableGames(cafe, limit: 6);
    if (availableGames.isNotEmpty) {
      return availableGames;
    }
    return _features(cafe);
  }

  // Distance + ETA (cached)
  (String dist, String? eta) _distanceLabel(Map<String, dynamic> cafe) {
    final (lat, lng) = _cafeLatLng(cafe);
    if (_userLat == null || _userLng == null || lat == null || lng == null) {
      return ('-- km', null);
    }
    final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    final km = _distanceKm.putIfAbsent(
      key,
      () => _haversineKm(_userLat!, _userLng!, lat, lng),
    );
    final etaMin = (_avgCitySpeedKmph > 0)
        ? (km / _avgCitySpeedKmph * 60).round()
        : null;
    return (
      '${km.toStringAsFixed(1)} km',
      etaMin != null ? '~$etaMin min' : null,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 600) {
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    // No paginated endpoint yet; kept as hook for future server-side pagination.
  }

  // ────────────────────────────── derived results ─────────────────────────────
  void _recomputeResults() {
    // IMPORTANT: clone before sorting/filtering to avoid mutating RxList in-place.
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
      _cafeController.cybercafes.cast<Map<String, dynamic>>(),
    );

    // search client-side (name/address)
    if (_currentQuery.isNotEmpty) {
      final q = _currentQuery.trim().toLowerCase();
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
                (cafe['cafe_name']?.toString().toLowerCase().contains(
                      'gaming',
                    ) ??
                    false);
          case 'Cafe':
            return cafe['type'] == 'cafe' ||
                (cafe['cafe_name']?.toString().toLowerCase().contains('cafe') ??
                    false);
          case 'Open Now':
            return _isShopOpen(cafe);
          case 'Nearby':
            // keep all for now; we will sort by distance below
            return true;
        }
        return true;
      }).toList();
    }

    // always sort nearest first when user location is available
    if (_hasLocationPermission) {
      final distByCafe = <String, double>{};
      results.sort((a, b) {
        final (la, loa) = _cafeLatLng(a);
        final (lb, lob) = _cafeLatLng(b);
        if (la == null || loa == null) return 1;
        if (lb == null || lob == null) return -1;
        final ka = '${la.toStringAsFixed(5)},${loa.toStringAsFixed(5)}';
        final kb = '${lb.toStringAsFixed(5)},${lob.toStringAsFixed(5)}';
        final da = distByCafe.putIfAbsent(
          ka,
          () => _haversineKm(_userLat!, _userLng!, la, loa),
        );
        final db = distByCafe.putIfAbsent(
          kb,
          () => _haversineKm(_userLat!, _userLng!, lb, lob),
        );
        return da.compareTo(db);
      });
    }

    if (!mounted) return;
    setState(() => _visibleResults = results);
  }

  // ───────────────────────────────── UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SearchResultHeader(
              location: widget.location,
              onBack: () => Get.back(),
            ),
            SearchResultSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isFocused: _isSearchFocused,
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  unawaited(
                    _segmentService.onCustomEvent('Search Performed', {
                      'query': query,
                      'source': 'search_result',
                    }),
                  );
                  unawaited(
                    _fbEventsService.onSearchPerformed(
                      query: query,
                      source: 'search_result',
                    ),
                  );
                }
                _loadCafes();
              },
              onClear: _clearSearch,
              showClear: _searchController.text.isNotEmpty,
            ),
            SearchResultFilters(
              filters: _filters,
              selected: _selectedFilter,
              onSelected: (filter) {
                setState(() => _selectedFilter = filter);
                unawaited(
                  _segmentService.onCustomEvent('Filters Applied', {
                    'screen': 'search_result',
                    'filters': [filter],
                  }),
                );
                unawaited(
                  _fbEventsService.onFiltersApplied(
                    screen: 'search_result',
                    filters: [filter],
                  ),
                );
                if (filter == 'Nearby') {
                  unawaited(
                    _segmentService.onCustomEvent('Sort Changed', {
                      'screen': 'search_result',
                      'sort_by': 'distance',
                    }),
                  );
                  unawaited(
                    _fbEventsService.onSortChanged(
                      screen: 'search_result',
                      sortBy: 'distance',
                    ),
                  );
                }
                _recomputeResults();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                onRefresh: () => _loadCafes(forceRefresh: true),
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _currentQuery = value;
      _recomputeResults();
      final query = value.trim();
      if (query.length >= 2) {
        unawaited(
          _segmentService.onCustomEvent('Search Performed', {
            'query': query,
            'source': 'search_result',
          }),
        );
        unawaited(
          _fbEventsService.onSearchPerformed(
            query: query,
            source: 'search_result',
          ),
        );
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _selectedFilter = 'All';
    });
    _recomputeResults();
  }

  Widget _buildResults() {
    return Obx(() {
      if (_cafeController.isLoading.value || _isSearching) {
        return const Center(child: RainbowGlowingLoader(size: 50));
      }

      final items = _visibleResults;
      if (items.isEmpty) {
        return const SearchResultEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            RepaintBoundary(child: _buildResultCard(items[index], index)),
      );
    });
  }

  Widget _buildResultCard(Map<String, dynamic> cafe, int index) {
    final isOpen = _isShopOpen(cafe);
    final imageUrl = _pickImage(cafe, index);
    final address = _safeAddress(cafe);
    final feats = _resultHighlights(cafe);
    final (dist, eta) = _distanceLabel(cafe);
    final title = (cafe['cafe_name'] ?? 'Unknown Cafe').toString();
    final type = (cafe['type'] ?? 'Gaming').toString();
    const rating = 4.5; // TODO: plug real rating when API provides

    return SearchResultCard(
      title: title,
      type: type,
      imageUrl: imageUrl,
      address: address,
      features: feats,
      isOpen: isOpen,
      distanceLabel: dist,
      etaLabel: eta,
      rating: rating,
      onViewDetails: isOpen
          ? () {
              final images = cafe['images'];
              List<dynamic> imagesList = [];
              if (images is List) {
                imagesList = images;
              } else if (images is String && images.isNotEmpty) {
                imagesList = [
                  {'url': images},
                ];
              }
              if (imagesList.isEmpty) {
                imagesList = [
                  {'url': _pickImage(cafe, index)},
                ];
              }

              final featsAll = _features(cafe);
              final availableGames = extractArenaAvailableGames(cafe);

              Get.to(
                () => ArenaDetailView(
                  images: imagesList,
                  title: title,
                  address: address,
                  openingHours: '9 AM - 12 AM', // TODO: plug real hours
                  availableGames: availableGames,
                  amenities: featsAll,
                  phone:
                      (cafe['phone'] ??
                              cafe['contact_number'] ??
                              'Phone not available')
                          .toString(),
                  email: (cafe['email'] ?? 'Email not available').toString(),
                  ownerName: (cafe['owner_name'] ?? 'Owner not available')
                      .toString(),
                  reviews: const ['Great place!', 'Loved it!'],
                  vendorId: cafe['vendor_id'],
                ),
              );
              final cafeId = (cafe['vendor_id'] ?? '').toString();
              unawaited(
                _segmentService.onGamingCafeViewed(
                  cafeId: cafeId,
                  cafeName: title,
                  location: address,
                  availableGames: availableGames,
                  email: (cafe['email'] ?? '').toString(),
                ),
              );
              unawaited(
                _fbEventsService.onGamingCafeViewed(
                  cafeId: cafeId,
                  location: address,
                  availableGames: availableGames,
                ),
              );
            }
          : null,
    );
  }
}
