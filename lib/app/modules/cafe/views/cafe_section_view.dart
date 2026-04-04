import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/config/app_keys.dart';
import 'package:hash/core/service/external_cafe_likes_service.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/location_permission_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:lottie/lottie.dart';
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
  static const String _sheetUrl = "https://onboard.hashforgamers.com/";
  static const String _hashCoinIconUrl =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1754940678/hash_loog_kze6kr.png';
  static const double _nearbyPlacesRadiusMeters = 10000;
  static const double _hashMatchDistanceKm = 0.35;
  static const List<String> _nearbyGamingKeywords = [
    'gaming cafe',
    'esports cafe',
    'gaming lounge',
    'lan center',
    'pc gaming',
    'gaming arena',
  ];
  static const int _externalCafeLikeGoal = 100;
  static const double _sectionGap = 12;
  bool _hasFetchedCafes = false;
  Worker? _hashCafeWorker;
  bool _isNearbyPlacesLoading = false;
  String? _nearbyPlacesError;
  String? _nearbyPlacesRequestKey;
  final List<Map<String, dynamic>> _nearbyOffHashCafes = [];
  DateTime? _nearbyPlacesCachedAt;
  final Map<String, List<Map<String, dynamic>>> _nearbyPlacesCache = {};
  static const Duration _nearbyPlacesCacheTtl = Duration(minutes: 10);
  final ExternalCafeLikesService _externalCafeLikesService =
      locator<ExternalCafeLikesService>();
  final LocationPermissionService _locationPermissionService =
      locator<LocationPermissionService>();
  final Set<String> _likingCafeIds = <String>{};

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

  late final loc.Location _loc = _locationPermissionService.location;
  StreamSubscription<loc.LocationData>? _locationSub;
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
      widget._cafeController.fetchCybercafes().then((_) {
        _triggerNearbyPlacesFetch(force: true);
      });
      _hasFetchedCafes = true;
    }
    _hashCafeWorker = ever(widget._cafeController.cybercafes, (_) {
      _triggerNearbyPlacesFetch(force: true);
    });
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
      final service = await _locationPermissionService.ensureServiceEnabled();
      if (!service) return;

      final perm = await _locationPermissionService.ensurePermission();
      if (perm != loc.PermissionStatus.granted &&
          perm != loc.PermissionStatus.grantedLimited) {
        return;
      }

      final ld = await _loc.getLocation();
      final hasInitialLocation = _applyResolvedLocation(ld);
      if (hasInitialLocation) return;

      _locationSub?.cancel();
      _locationSub = _loc.onLocationChanged.listen((data) {
        final resolved = _applyResolvedLocation(data);
        if (resolved) {
          _locationSub?.cancel();
        }
      });
    } catch (_) {
      /* ignore */
    }
  }

  @override
  void dispose() {
    _hashCafeWorker?.dispose();
    _locationSub?.cancel();
    super.dispose();
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

  bool _hasUsableCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return false;
    return true;
  }

  bool _hasMeaningfulLocationChange(
    double? oldLat,
    double? oldLng,
    double nextLat,
    double nextLng,
  ) {
    if (!_hasUsableCoordinates(oldLat, oldLng)) return true;
    return _haversineKm(oldLat!, oldLng!, nextLat, nextLng) > 0.15;
  }

  bool _applyResolvedLocation(loc.LocationData data) {
    final lat = data.latitude;
    final lng = data.longitude;
    if (!_hasUsableCoordinates(lat, lng)) return false;

    final hasChanged = _hasMeaningfulLocationChange(
      _userLat,
      _userLng,
      lat!,
      lng!,
    );
    if (!hasChanged) return true;
    if (!mounted) return false;

    setState(() {
      _userLat = lat;
      _userLng = lng;
    });
    _triggerNearbyPlacesFetch(force: true);
    return true;
  }

  String get _placesApiKey {
    final key = AppKeys.googlePlacesApiKey;
    if (key.isNotEmpty && key != '...') return key;
    return Platform.isAndroid
        ? 'AIzaSyAIeaszJ60ZcjL9hNYpsQ_JD8w8J2vnmuQ'
        : 'AIzaSyDjaI5XOoq4r0AbJVfDSz9tiQqLGBC_yNU';
  }

  Future<void> _triggerNearbyPlacesFetch({bool force = false}) async {
    if (_userLat == null || _userLng == null) return;
    if (widget._cafeController.isLoading.value) return;

    final requestKey =
        '${_userLat!.toStringAsFixed(4)},${_userLng!.toStringAsFixed(4)}:${widget._cafeController.cybercafes.length}';
    final isCacheFresh =
        _nearbyPlacesCachedAt != null &&
        DateTime.now().difference(_nearbyPlacesCachedAt!) <=
            _nearbyPlacesCacheTtl;

    if (isCacheFresh && _nearbyPlacesCache.containsKey(requestKey)) {
      if (!mounted) return;
      setState(() {
        _nearbyPlacesRequestKey = requestKey;
        _nearbyPlacesError = null;
        _nearbyOffHashCafes
          ..clear()
          ..addAll(_nearbyPlacesCache[requestKey]!);
      });
      return;
    }

    if (!force &&
        (_isNearbyPlacesLoading || _nearbyPlacesRequestKey == requestKey)) {
      return;
    }

    _nearbyPlacesRequestKey = requestKey;
    await _fetchNearbyOffHashCafes();
  }

  Future<void> _fetchNearbyOffHashCafes() async {
    if (_userLat == null || _userLng == null) return;
    if (_placesApiKey.isEmpty || _placesApiKey == '...') return;

    if (mounted) {
      setState(() {
        _isNearbyPlacesLoading = true;
        _nearbyPlacesError = null;
      });
    }

    try {
      final dio = locator<NetworkProvider>().noAuth();
      final uniquePlaces = <String, Map<String, dynamic>>{};

      for (final keyword in _nearbyGamingKeywords) {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/nearbysearch/json',
          {
            'location': '${_userLat!},${_userLng!}',
            'radius': _nearbyPlacesRadiusMeters.round().toString(),
            'keyword': keyword,
            'key': _placesApiKey,
          },
        );

        final response = await dio.get(uri.toString());
        if (response.statusCode != 200 || response.data is! Map) continue;

        final results = (response.data['results'] as List?) ?? const [];
        for (final rawPlace in results) {
          if (rawPlace is! Map) continue;
          final place = Map<String, dynamic>.from(rawPlace);
          final placeId = place['place_id']?.toString();
          if (placeId == null || placeId.isEmpty) continue;
          uniquePlaces[placeId] = place;
        }
      }

      final filteredPlaces =
          uniquePlaces.values.where(_isEligibleNearbyPlace).toList()
            ..sort((a, b) {
              final aDistance = _distanceFromUserToPlace(a) ?? double.infinity;
              final bDistance = _distanceFromUserToPlace(b) ?? double.infinity;
              return aDistance.compareTo(bDistance);
            });

      if (!mounted) return;
      setState(() {
        _nearbyPlacesCachedAt = DateTime.now();
        _nearbyPlacesCache[_nearbyPlacesRequestKey!] =
            List<Map<String, dynamic>>.from(filteredPlaces);
        _nearbyOffHashCafes
          ..clear()
          ..addAll(filteredPlaces);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyPlacesError = e.toString();
        final cachedResults = _nearbyPlacesRequestKey == null
            ? null
            : _nearbyPlacesCache[_nearbyPlacesRequestKey!];
        if (cachedResults != null) {
          _nearbyOffHashCafes
            ..clear()
            ..addAll(cachedResults);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isNearbyPlacesLoading = false;
        });
      }
    }
  }

  bool _isEligibleNearbyPlace(Map<String, dynamic> place) {
    final businessStatus =
        place['business_status']?.toString().toUpperCase() ?? '';
    if (businessStatus == 'CLOSED_PERMANENTLY') return false;

    final distanceKm = _distanceFromUserToPlace(place);
    if (distanceKm == null || distanceKm > (_nearbyPlacesRadiusMeters / 1000)) {
      return false;
    }

    if (!_looksLikeGamingCafe(place)) return false;
    return !_isHashCafePlace(place);
  }

  bool _looksLikeGamingCafe(Map<String, dynamic> place) {
    final name = (place['name']?.toString() ?? '').toLowerCase();
    final vicinity = (place['vicinity']?.toString() ?? '').toLowerCase();
    final combined = '$name $vicinity';

    const positiveTokens = <String>{
      'gaming',
      'gamer',
      'gamers',
      'esports',
      'e-sports',
      'ps5',
      'playstation',
      'xbox',
      'lan',
      'console',
      'pc cafe',
      'pc gaming',
      'gaming lounge',
      'gaming arena',
      'game zone',
      'gamezone',
      'battle',
      'arena',
    };

    const negativeTokens = <String>{
      'computer shop',
      'computer store',
      'computer sales',
      'computer service',
      'computer repair',
      'laptop repair',
      'laptop store',
      'printer',
      'photocopy',
      'xerox',
      'internet cafe',
      'cyber cafe',
      'cybercafe',
      'cyber cafe and',
      'infotech',
      'infosys',
      'solution',
      'solutions',
      'systems',
      'technologies',
      'technology',
      'electronics',
      'electronic',
      'mobile shop',
      'repairing',
      'service center',
      'service centre',
      'it services',
      'broadband',
      'cctv',
      'stationery',
      'typing',
    };

    for (final token in negativeTokens) {
      if (combined.contains(token)) return false;
    }

    final types =
        (place['types'] as List?)
            ?.map((type) => type.toString().toLowerCase())
            .toSet() ??
        <String>{};

    const blockedTypes = <String>{
      'computer_store',
      'electronics_store',
      'hardware_store',
      'store',
      'shopping_mall',
      'home_goods_store',
      'repair_shop',
    };
    if (types.intersection(blockedTypes).isNotEmpty) return false;

    for (final token in positiveTokens) {
      if (combined.contains(token)) return true;
    }

    return false;
  }

  bool _isHashCafePlace(Map<String, dynamic> place) {
    final placeName = _normalizeCafeName(place['name']?.toString() ?? '');
    final placeLat = _placeLat(place);
    final placeLng = _placeLng(place);

    for (final rawCafe in widget._cafeController.cybercafes) {
      if (rawCafe is! Map) continue;
      final cafe = Map<String, dynamic>.from(rawCafe);
      final cafeName = _normalizeCafeName(cafe['cafe_name']?.toString() ?? '');
      final cafeLat = _cafeLat(cafe);
      final cafeLng = _cafeLng(cafe);

      final sameName =
          placeName.isNotEmpty &&
          cafeName.isNotEmpty &&
          (placeName == cafeName ||
              placeName.contains(cafeName) ||
              cafeName.contains(placeName));

      final sameLocation =
          placeLat != null &&
          placeLng != null &&
          cafeLat != null &&
          cafeLng != null &&
          _haversineKm(placeLat, placeLng, cafeLat, cafeLng) <=
              _hashMatchDistanceKm;

      if (sameName && sameLocation) return true;
      if (sameLocation && _sharedCafeTokenScore(placeName, cafeName) >= 0.6) {
        return true;
      }
    }

    return false;
  }

  String _normalizeCafeName(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(
          RegExp(
            r'\b(cafe|café|cyber|gaming|esports|lounge|zone|hub|center|centre|arena)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  double _sharedCafeTokenScore(String a, String b) {
    final aTokens = a.split(' ').where((token) => token.isNotEmpty).toSet();
    final bTokens = b.split(' ').where((token) => token.isNotEmpty).toSet();
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;

    final intersection = aTokens.intersection(bTokens).length;
    final base = math.max(aTokens.length, bTokens.length);
    return base == 0 ? 0 : intersection / base;
  }

  double? _placeLat(Map<String, dynamic> place) {
    final geometry = place['geometry'];
    final location = geometry is Map ? geometry['location'] : null;
    if (location is! Map) return null;
    return _toDouble(location['lat']);
  }

  double? _placeLng(Map<String, dynamic> place) {
    final geometry = place['geometry'];
    final location = geometry is Map ? geometry['location'] : null;
    if (location is! Map) return null;
    return _toDouble(location['lng']);
  }

  double? _distanceFromUserToPlace(Map<String, dynamic> place) {
    if (_userLat == null || _userLng == null) return null;
    final lat = _placeLat(place);
    final lng = _placeLng(place);
    if (lat == null || lng == null) return null;
    return _haversineKm(_userLat!, _userLng!, lat, lng);
  }

  String _placePhotoUrl(Map<String, dynamic> place) {
    final photos = place['photos'];
    if (photos is List && photos.isNotEmpty && photos.first is Map) {
      final ref = photos.first['photo_reference']?.toString();
      if (ref != null && ref.isNotEmpty) {
        return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1200&photo_reference=$ref&key=$_placesApiKey';
      }
    }
    return 'https://next-level.gg/assets/cafes/11.jpg';
  }

  Future<void> _openNearbyPlaceInMaps(Map<String, dynamic> place) async {
    final name = place['name']?.toString() ?? 'Cafe';
    final placeId = place['place_id']?.toString();
    final query = Uri.encodeComponent(name);
    final url = placeId != null && placeId.isNotEmpty
        ? 'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=$placeId'
        : 'https://www.google.com/maps/search/?api=1&query=$query';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Maps', 'Could not open Google Maps');
    }
  }

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
        border: Border.all(
          color: const Color(0xffFF8A1F).withValues(alpha: 0.45),
        ),
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

  Widget _buildNearbyOffHashSection(double cardWidth) {
    return _buildExternalCafeSection(
      cardWidth: cardWidth,
      title: 'More Cafes Near You',
    );
  }

  Widget _buildExternalCafeSection({
    required double cardWidth,
    required String title,
  }) {
    if (_userLat == null || _userLng == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _sectionGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                'Within 10 km',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2114).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFB357).withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB357).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 11,
                  color: Color(0xFFFFC777),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Likes show demand for Hash onboarding. If 100 gamers like a cafe, we can approach the cafe team to bring it onto Hash.',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFFD49C),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isNearbyPlacesLoading)
          SizedBox(
            height: 246,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  width: cardWidth,
                  height: 246,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ),
          )
        else if (_nearbyOffHashCafes.isNotEmpty)
          SizedBox(
            height: 246,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _nearbyOffHashCafes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final place = _nearbyOffHashCafes[index];
                final cafeId = _externalCafeLikesService.cafeDocIdFromPlace(
                  place,
                );
                final imageUrl = _placePhotoUrl(place);
                final rating = _toDouble(place['rating']);
                final ratingCount = place['user_ratings_total'];
                final distanceKm = _distanceFromUserToPlace(place);
                final vicinity =
                    place['vicinity']?.toString() ?? 'Address unavailable';
                final isLiking = _likingCafeIds.contains(cafeId);

                return BounceTap(
                  onTap: () => _openNearbyPlaceInMaps(place),
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xff0E0E0E),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: cardWidth,
                            height: 246,
                            placeholder: (_, __) => Container(
                              color: const Color(0xff1a1a1a),
                              child: const Center(
                                child: RainbowGlowingLoader(size: 40),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xff1a1a1a),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.location_city,
                                color: Colors.white54,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  62,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF3D2E12,
                                        ).withValues(alpha: 0.96),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFFFB357,
                                          ).withValues(alpha: 0.55),
                                        ),
                                      ),
                                      child: Text(
                                        'Not on Hash yet',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFFFC777),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      toStartCase(
                                        place['name']?.toString() ??
                                            'Unknown Cafe',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vicinity,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          distanceKm == null
                                              ? '-- km'
                                              : '${distanceKm.toStringAsFixed(1)} km',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Color(0xFFFFC83D),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating == null
                                              ? 'N/A'
                                              : rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (ratingCount != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '($ratingCount)',
                                            style: GoogleFonts.inter(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>
                                    >(
                                      stream: _externalCafeLikesService
                                          .watchCafe(cafeId),
                                      builder: (context, snapshot) {
                                        final totalLikes =
                                            (snapshot.data?.data()?['total_likes']
                                                        as num? ??
                                                    0)
                                                .toInt();
                                        final clampedLikes = totalLikes.clamp(
                                          0,
                                          _externalCafeLikeGoal,
                                        );
                                        final reachedGoal =
                                            totalLikes >= _externalCafeLikeGoal;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.18,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white10,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.favorite_rounded,
                                                    size: 13,
                                                    color: Color(0xFFFF8C8C),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      '$totalLikes gamers want this cafe on Hash',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        color: const Color(
                                                          0xFFFFD49C,
                                                        ),
                                                        fontSize: 9.6,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.05,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              reachedGoal
                                                  ? 'Target reached. This cafe has enough demand for Hash onboarding.'
                                                  : '${_externalCafeLikeGoal - clampedLikes} more likes to make this cafe onboarding-ready.',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: reachedGoal
                                                    ? const Color(0xff74FF74)
                                                    : Colors.white60,
                                                fontSize: 9.2,
                                                fontWeight: FontWeight.w500,
                                                height: 1.05,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  stream: _externalCafeLikesService.watchCafe(
                                    cafeId,
                                  ),
                                  builder: (context, cafeSnapshot) {
                                    final totalLikes =
                                        (cafeSnapshot.data
                                                        ?.data()?['total_likes']
                                                    as num? ??
                                                0)
                                            .toInt();
                                    final clampedLikes = totalLikes.clamp(
                                      0,
                                      _externalCafeLikeGoal,
                                    );
                                    final progress =
                                        clampedLikes / _externalCafeLikeGoal;
                                    final reachedGoal =
                                        totalLikes >= _externalCafeLikeGoal;

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    child: LinearProgressIndicator(
                                                      value: progress
                                                          .toDouble(),
                                                      minHeight: 6,
                                                      backgroundColor:
                                                          Colors.white12,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            reachedGoal
                                                                ? const Color(
                                                                    0xff00DC00,
                                                                  )
                                                                : const Color(
                                                                    0xFFFFB357,
                                                                  ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$clampedLikes/100',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        StreamBuilder<bool>(
                                          stream: _externalCafeLikesService
                                              .watchIsLiked(cafeId),
                                          builder: (context, likedSnapshot) {
                                            final isLiked =
                                                likedSnapshot.data == true ||
                                                isLiking;
                                            return SizedBox(
                                              height: 32,
                                              child: OutlinedButton(
                                                onPressed: isLiked
                                                    ? null
                                                    : () =>
                                                          _handleLikeExternalCafe(
                                                            cafeId: cafeId,
                                                            place: place,
                                                          ),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 0,
                                                      ),
                                                  backgroundColor:
                                                      (isLiked
                                                              ? const Color(
                                                                  0xFF3A1818,
                                                                )
                                                              : const Color(
                                                                  0xFF1E2A1E,
                                                                ))
                                                          .withValues(
                                                            alpha: 0.55,
                                                          ),
                                                  foregroundColor: Colors.white,
                                                  side: BorderSide(
                                                    color: isLiked
                                                        ? const Color(
                                                            0xFFFF8C8C,
                                                          )
                                                        : const Color(
                                                            0xff74FF74,
                                                          ),
                                                    width: 1,
                                                  ),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  isLiked
                                                      ? '❤️ Liked'
                                                      : '❤️ Like',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
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
          )
        else if (_nearbyPlacesError == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'No additional cafes found nearby outside Hash.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildBrowseEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xff121212),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Gaming Cafes Found Nearby',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Help seed the network around you. Suggest a venue, invite other gamers, or start one yourself.',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _chooseOpenSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00DC00),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Suggest a Cafe',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _showEmptyStateCtaMessage(
                      'Invite Friends',
                      'Invite flow UI can be connected next.',
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Invite Friends',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _showEmptyStateCtaMessage(
                      'Start a Gaming Cafe',
                      'Startup journey CTA UI is ready for wiring.',
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Start a Gaming Cafe',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEmptyStateCtaMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xff1A1A1A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> _handleLikeExternalCafe({
    required String cafeId,
    required Map<String, dynamic> place,
  }) async {
    if (_likingCafeIds.contains(cafeId)) return;

    setState(() {
      _likingCafeIds.add(cafeId);
    });

    try {
      final liked = await _externalCafeLikesService.likeCafe(
        cafeId: cafeId,
        place: place,
      );
      if (!liked) {
        Get.snackbar('Like', 'You already liked this cafe.');
      } else {
        await _rewardLikeWithHashCoins();
      }
    } catch (_) {
      Get.snackbar('Like', 'Could not register your like right now.');
    } finally {
      if (mounted) {
        setState(() {
          _likingCafeIds.remove(cafeId);
        });
      }
    }
  }

  Future<void> _rewardLikeWithHashCoins() async {
    try {
      final remoteRepo = locator<RemoteRepoInterface>();
      await remoteRepo.addHashCoins(amount: 10, source: 'external_cafe_like');
      if (!mounted) return;

      try {
        context.read<HashCoinCubit>().getHashCoin();
      } catch (_) {
        // ignore if cubit is unavailable in current subtree
      }

      await _showHashCoinRewardPopup();
    } catch (_) {
      // keep the like success even if reward credit fails
    }
  }

  Future<void> _showHashCoinRewardPopup() async {
    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFC83D).withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFD46A).withValues(alpha: 0.22),
                      const Color(0xFFFF9E2C).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFFC83D).withValues(alpha: 0.28),
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: _hashCoinIconUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: RainbowGlowingLoader(size: 16)),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC83D),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  'Reward Unlocked',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD777),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thanks for the like',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC83D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFC83D).withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: _hashCoinIconUrl,
                      width: 20,
                      height: 20,
                      placeholder: (_, __) =>
                          const Center(child: RainbowGlowingLoader(size: 8)),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFC83D),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You received 10 HashCoins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFD777),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Each like helps us spot cafes worth onboarding next.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Get.back<void>(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC83D),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
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
              'Browse Cafes',
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
                      'Onboard Your Cafe',
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
        const SizedBox(height: 0),
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

          final double cardWidth = MediaQuery.of(context).size.width - 30;
          final sortedCafes = _sortedCafesByNearest(
            widget._cafeController.cybercafes,
          );
          final nearestKm = _nearestDistanceKm(sortedCafes);
          final showComingSoon = nearestKm != null && nearestKm > 20;

          final hasInternalCafes = sortedCafes.isNotEmpty;
          final hasExternalCafes = _nearbyOffHashCafes.isNotEmpty;
          final shouldShowExternalLoading =
              !hasInternalCafes && _isNearbyPlacesLoading;
          final showExternalSection =
              hasExternalCafes || shouldShowExternalLoading;

          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (hasInternalCafes) ...[
                if (showComingSoon) _comingSoonNearYouBanner(),
                SizedBox(
                  height: 210,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 3),
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
                        final location =
                            cafe['location']?['address'] ?? 'Unknown';
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
                            {
                              'url':
                                  'https://next-level.gg/assets/cafes/11.jpg',
                            },
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
                            ownerName:
                                cafe['owner_name'] ?? 'Owner not available',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    filter: ImageFilter.blur(
                                      sigmaX: 4,
                                      sigmaY: 4,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                    cafe['cafe_name']
                                                            ?.toString() ??
                                                        'Unknown Cafe',
                                                  ),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              CachedNetworkImage(
                                                imageUrl:
                                                    'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/gaming-pad-02_hvvehr.png',
                                                height: 16,
                                                width: 16,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    const Center(
                                                      child:
                                                          RainbowGlowingLoader(
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFB020,
                                                  ).withValues(alpha: 0.95),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: Lottie.asset(
                                                        'assets/fire.json',
                                                        fit: BoxFit.contain,
                                                        repeat: true,
                                                        animate: true,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Filling Fast',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.black,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (hasInternalCafes && showExternalSection)
                const SizedBox(height: _sectionGap),
              if (hasInternalCafes && showExternalSection)
                _buildNearbyOffHashSection(cardWidth),
              if (!hasInternalCafes && showExternalSection)
                _buildExternalCafeSection(
                  cardWidth: cardWidth,
                  title: 'Help Bring Cafes to Hash',
                ),
              if (!hasInternalCafes &&
                  !hasExternalCafes &&
                  !_isNearbyPlacesLoading)
                const SizedBox(height: 4),
              if (!hasInternalCafes &&
                  !hasExternalCafes &&
                  !_isNearbyPlacesLoading)
                _buildBrowseEmptyState(),
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
