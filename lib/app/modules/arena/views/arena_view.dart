import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/views/search_result.dart';
import 'package:hash/config/app_keys.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    hide NetworkProvider;
import 'package:url_launcher/url_launcher.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import '../../../../utils/service.dart';
import '../../../../utils/widgets/loader.dart';
import 'arena_view_detailed.dart';

class ArenaView extends StatefulWidget {
  const ArenaView({super.key});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  /* ────────────────────────────────────────────────────────────────────────── */
  /*  STATE                                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  final CybercafesController _cafeCtr = Get.put(
    CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
  );
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  late GoogleMapController _mapCtr;
  final loc.Location _loc = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSub;
  late final Worker _cafesWorker;
  bool _hasLocationPermission = false; // add

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  final _polylinePoints = PolylinePoints(apiKey: _gmapsKey); // was ''

  final TextEditingController _searchCtl = TextEditingController();
  final PageController _cafePageController = PageController(
    viewportFraction: 0.9,
  );
  Timer? _camDebounce;

  LatLng? _userLatLng;
  String? _selectedCafeId;
  String _mapStyle = '';

  // Location-based filtering
  String? _userState;
  final RxList<Map<String, dynamic>> _filteredCafes =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLocationFiltering = false.obs;
  final RxBool _showingAllCafes = false.obs;

  /// Directions API response cache  (cafeId  ->  distance / duration)
  final Map<String, Map<String, String>> _distanceCache = {};
  final Map<String, Future<Map<String, String>>> _distanceFutureCache = {};

  /// ⚠️  Replace with build-time env variable or secure storage
  static const _gmapsKey = AppKeys.googleMapsApiKey;
  bool _mapReady = false; // NEW
  bool _playedZoom = false; // NEW

  BitmapDescriptor? _markerUser, _markerCafe, _markerCafeHighlighted;
  String _normState(String? s) {
    if (s == null) return '';
    final t = s.trim().toLowerCase();
    if (t == 'mh' || t == 'maharastra') return 'maharashtra';
    return t;
  }

  List<Map<String, dynamic>> _sortCafesByDistance(
    List<Map<String, dynamic>> cafes,
  ) {
    if (_userLatLng == null) return cafes;
    final sorted = List<Map<String, dynamic>>.from(cafes);
    sorted.sort((a, b) {
      final aPos = _latLngFromCafe(a);
      final bPos = _latLngFromCafe(b);
      final aDist = aPos == null
          ? double.infinity
          : _distanceInKm(_userLatLng!, aPos);
      final bDist = bPos == null
          ? double.infinity
          : _distanceInKm(_userLatLng!, bPos);
      return aDist.compareTo(bDist);
    });
    return sorted;
  }

  double _distanceInKm(LatLng from, LatLng to) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (pi / 180.0);

  void _filterCafesByState() {
    final user = _normState(_userState);
    if (user.isEmpty) {
      _filteredCafes.assignAll(
        _sortCafesByDistance(_cafeCtr.cybercafes.cast<Map<String, dynamic>>()),
      );
      return;
    }
    final filtered = _cafeCtr.cybercafes.where((c) {
      final cafeState = _normState(c['address']?['state']);
      return cafeState == user;
    }).toList();
    _filteredCafes.assignAll(
      _sortCafesByDistance(filtered.cast<Map<String, dynamic>>()),
    );
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LIFECYCLE                                                                */
  /* ────────────────────────────────────────────────────────────────────────── */

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _cafesWorker = ever<List<dynamic>>(_cafeCtr.cybercafes, (_) {
      _applyCafeFilterAndRefresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initLocation();
      if (!mounted) return;
      if (_cafeCtr.cybercafes.isEmpty && !_cafeCtr.isLoading.value) {
        await _cafeCtr.fetchCybercafes();
      }
      if (!mounted) return;
      if (_userLatLng != null) {
        await _getUserStateAndFilterCafes();
      } else {
        _applyCafeFilterAndRefresh();
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _cafesWorker.dispose();
    _searchCtl.dispose();
    _cafePageController.dispose();
    _camDebounce?.cancel();
    if (_mapReady) {
      try {
        _mapCtr.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  ASSET & MARKER HELPERS                                                   */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _loadAssets() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.json');
    } catch (_) {
      _mapStyle = ''; // fallback
    }

    try {
      _markerUser = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/custom_marker.png',
      );
    } catch (_) {
      _markerUser = BitmapDescriptor.defaultMarker;
    }

    try {
      _markerCafe = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/logo2.png',
      );
    } catch (_) {
      _markerCafe = BitmapDescriptor.defaultMarker;
    }

    _markerCafeHighlighted = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );

    if (!mounted) return;
    if (_mapReady && _mapStyle.isNotEmpty) {
      try {
        await _mapCtr.setMapStyle(_mapStyle);
      } catch (_) {}
    }
    _refreshCafeMarkers();
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LOCATION INIT                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

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
        return; // don't enable myLocation
      }

      if (!mounted) return;
      setState(() => _hasLocationPermission = true);

      final locData = await _loc.getLocation();
      final lat = locData.latitude;
      final lng = locData.longitude;

      // Guard: plugin may return null or (0,0) initially
      if (lat == null || lng == null) return;
      if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return;

      _userLatLng = LatLng(lat, lng);
      _tryPlayZoom();

      // Optional: first valid update via stream
      _locationSub?.cancel();
      _locationSub = _loc.onLocationChanged.listen((d) {
        final la = d.latitude, lo = d.longitude;
        if (la != null && lo != null) {
          if (_userLatLng == null) {
            _userLatLng = LatLng(la, lo);
            _addUserMarker();
            _tryPlayZoom();
            _locationSub?.cancel();
          }
        }
      });
    } catch (_) {
      /* swallow */
    }
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  CAMERA & MOVEMENT                                                        */
  /* ────────────────────────────────────────────────────────────────────────── */

  void _smoothMoveCamera(LatLng? target, {double zoom = 15}) {
    if (!_mapReady || target == null) return;
    _camDebounce?.cancel();
    _camDebounce = Timer(const Duration(milliseconds: 280), () {
      _mapCtr.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    });
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  GTA-STYLE ZOOM LOGIC                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _playZoomAnimation() async {
    if (_userLatLng == null) return;
    _playedZoom = true;

    // start far away
    await _mapCtr.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLatLng!, zoom: 4),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // zoom mid-range
    await _mapCtr.animateCamera(CameraUpdate.zoomTo(9));
    await Future.delayed(const Duration(milliseconds: 300));

    // final close-up
    await _mapCtr.animateCamera(CameraUpdate.zoomTo(15));
  }

  void _tryPlayZoom() {
    if (_mapReady && _userLatLng != null && !_playedZoom) {
      _playZoomAnimation();
    }
  }
  /* ────────────────────────────────────────────────────────────────────────── */
  /*  MARKERS                                                                  */
  /* ────────────────────────────────────────────────────────────────────────── */

  LatLng? _latLngFromCafe(Map<String, dynamic> cafe) {
    final locData = cafe['address'] ?? cafe['location'] ?? {};
    final lat = double.tryParse('${locData['latitude']}');
    final lng = double.tryParse('${locData['longitude']}');
    if (lat == null || lng == null) return null;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return null;
    return LatLng(lat, lng);
  }

  String _formatAddress(Map<String, dynamic> cafe) {
    final address = cafe['address'];
    if (address == null) return 'Address not available';

    final addressLine1 = address['addressLine1'] ?? '';
    final addressLine2 = address['addressLine2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final pincode = address['pincode'] ?? '';

    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      pincode,
    ].where((part) => part.isNotEmpty).toList();

    return parts.join(', ');
  }

  String _formatOpeningHours(Map<String, dynamic> cafe) {
    // Get opening and closing times from the API response
    final openingTime = cafe['opening_time'] ?? '';
    final closingTime = cafe['closing_time'] ?? '';

    if (openingTime.isNotEmpty && closingTime.isNotEmpty) {
      // Format the times to be more readable (remove seconds)
      final formattedOpening = _formatTimeForDisplay(openingTime);
      final formattedClosing = _formatTimeForDisplay(closingTime);
      return '$formattedOpening - $formattedClosing';
    }

    // Fallback to status
    final status = cafe['status'];
    if (status == 'active' || status == 'verified') {
      return 'Open';
    } else if (status == 'pending_verification' || status == 'inactive') {
      return 'Pending Verification';
    }

    return 'Hours not available';
  }

  String _formatTimeForDisplay(String timeStr) {
    try {
      // Remove seconds from time format like "09:00:00" -> "09:00"
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
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

    // Check for status field
    final status = cafe['status'];
    if (status != null) {
      final statusText = status.toString().toLowerCase();
      // For pending_verification status, determine based on opening hours
      if (statusText == 'pending_verification') {
        return _isCurrentlyOpen(cafe);
      }
      if (statusText == 'closed' || statusText == 'inactive') return false;
      return statusText == 'active' ||
          statusText == 'verified' ||
          statusText == 'open' ||
          statusText == 'operational';
    }

    // Check for operating_status field
    final operatingStatus = cafe['operating_status'];
    if (operatingStatus != null) {
      return operatingStatus == 'open' || operatingStatus == 'active';
    }

    // Check for availability field
    final availability = cafe['availability'];
    if (availability != null) {
      return availability == 'available' || availability == 'open';
    }

    // Determine status based on opening/closing times
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

  bool _isCurrentlyOpen(Map<String, dynamic> cafe) {
    try {
      // Get opening and closing times from the API response
      final openingTime = cafe['opening_time'] ?? '';
      final closingTime = cafe['closing_time'] ?? '';

      if (openingTime.isEmpty || closingTime.isEmpty) {
        return false; // Can't determine without times
      }

      // Parse current time
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Parse opening and closing times
      final opening = _parseTime(openingTime);
      final closing = _parseTime(closingTime);
      final current = _parseTime(currentTime);

      if (opening == null || closing == null || current == null) {
        return false;
      }

      // Handle cases where closing time is on the next day (e.g., 23:00 - 02:00)
      if (closing < opening) {
        // Shop is open if current time is after opening OR before closing
        return current >= opening || current <= closing;
      } else {
        // Normal case: opening time is before closing time
        return current >= opening && current <= closing;
      }
    } catch (e) {
      return false;
    }
  }

  int? _parseTime(String timeStr) {
    try {
      // Handle various time formats: "09:00", "9:00", "9:00 AM", "09:00:00"
      final cleanTime = timeStr.trim().toUpperCase();

      // Remove AM/PM and convert to 24-hour format
      String time24 = cleanTime;
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        final parts = cleanTime.split(' ');
        final time = parts[0];
        final period = parts[1];

        final timeParts = time.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        time24 =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }

      // Convert to minutes since midnight for easy comparison
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  void _addUserMarker() {
    _refreshCafeMarkers();
  }

  void _applyCafeFilterAndRefresh() {
    if (_showingAllCafes.value || _userState == null || _userState!.isEmpty) {
      _filteredCafes.assignAll(
        _sortCafesByDistance(_cafeCtr.cybercafes.cast<Map<String, dynamic>>()),
      );
    } else {
      _filterCafesByState();
    }
    _refreshCafeMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _filteredCafes.isEmpty) return;
      final targetIndex = _cafePageController.hasClients
          ? (_cafePageController.page?.round() ?? 0)
          : 0;
      final safeIndex = targetIndex.clamp(0, _filteredCafes.length - 1);
      _focusCafeByIndex(safeIndex);
    });
  }

  void _focusCafeByIndex(int index) {
    if (index < 0 || index >= _filteredCafes.length) return;
    final cafe = _filteredCafes[index];
    final id = '${cafe['id'] ?? cafe.hashCode}';
    final pos = _latLngFromCafe(cafe);
    if (pos == null) return;
    _selectedCafeId = id;
    _smoothMoveCamera(pos, zoom: 16);
    _refreshCafeMarkers();
  }

  void _pruneDistanceCaches() {
    final visibleIds = _filteredCafes
        .map((c) => '${c['id'] ?? c.hashCode}')
        .toSet();
    _distanceCache.removeWhere((key, _) => !visibleIds.contains(key));
    _distanceFutureCache.removeWhere((key, _) => !visibleIds.contains(key));
  }

  void _refreshCafeMarkers() {
    final nextMarkers = <Marker>{};
    if (_userLatLng != null) {
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _userLatLng!,
          icon: _markerUser ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }
    for (final cafe in _filteredCafes) {
      final id = '${cafe['id'] ?? cafe.hashCode}';
      final pos = _latLngFromCafe(cafe);
      if (pos == null) continue; // skip invalid
      nextMarkers.add(
        Marker(
          markerId: MarkerId('cafe_$id'),
          position: pos,
          icon: id == _selectedCafeId
              ? (_markerCafeHighlighted ?? BitmapDescriptor.defaultMarker)
              : (_markerCafe ?? BitmapDescriptor.defaultMarker),
          infoWindow: InfoWindow(title: cafe['cafe_name'] ?? 'Cafe'),
          onTap: () {
            _selectedCafeId = id;
            _smoothMoveCamera(pos, zoom: 16);
            _refreshCafeMarkers();
          },
        ),
      );
    }
    markers
      ..clear()
      ..addAll(nextMarkers);
    _pruneDistanceCaches();
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  DISTANCE + DURATION (Directions API)                                     */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<Map<String, String>> _distanceInfo(LatLng dest, String id) async {
    const fallback = {'distance': '--', 'duration': '--'};

    if (_userLatLng == null) return fallback;
    if (_gmapsKey.isEmpty) return fallback;

    final cached = _distanceCache[id];
    if (cached != null) return cached;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_userLatLng!.latitude},${_userLatLng!.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving'
        '&key=$_gmapsKey',
      );
      final dio = locator<NetworkProvider>().noAuth();
      final res = await dio.get(url.toString());

      if (res.statusCode == 200) {
        final data = res.data is String
            ? json.decode(res.data as String) as Map<String, dynamic>
            : res.data as Map<String, dynamic>;
        final routes = (data['routes'] as List?) ?? const [];
        if (routes.isNotEmpty) {
          final leg = routes[0]['legs'][0];
          return _distanceCache[id] = {
            'distance': leg['distance']?['text'] ?? '--',
            'duration': leg['duration']?['text'] ?? '--',
          };
        }
      }
    } catch (_) {
      // ignore and fall back
    }

    return _distanceCache[id] = Map<String, String>.from(fallback);
  }

  Future<Map<String, String>> _distanceFuture(String id, LatLng? pos) {
    if (pos == null) {
      return Future.value({'distance': '--', 'duration': '--'});
    }
    return _distanceFutureCache[id] ??= _distanceInfo(pos, id);
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  ROUTE DRAWING                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _drawRoute(LatLng dest) async {
    if (_userLatLng == null || !_mapReady) return;

    final request = PolylineRequest(
      origin: PointLatLng(_userLatLng!.latitude, _userLatLng!.longitude),
      destination: PointLatLng(dest.latitude, dest.longitude),
      mode: TravelMode.driving,
    );

    final result = await _polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );
    if (result.points.isEmpty) {
      Get.snackbar('Route', 'No route found');
      return;
    }

    final pts = result.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    polylines
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xff00DC00),
          width: 6,
          points: pts,
        ),
      );

    // Fit bounds
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapCtr.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  EXTERNAL MAP LAUNCH                                                      */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _openExternalMaps(LatLng dest) async {
    if (_userLatLng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_userLatLng!.latitude},${_userLatLng!.longitude}'
      '&destination=${dest.latitude},${dest.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open Google Maps');
    }
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LOCATION-BASED FILTERING                                                 */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _getUserStateAndFilterCafes() async {
    if (_userLatLng == null) {
      _applyCafeFilterAndRefresh();
      return;
    }

    try {
      _isLocationFiltering.value = true;

      // Reset showing all cafes state when location changes
      _showingAllCafes.value = false;

      // Get user's state from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final previousState = (_userState ?? '').trim();
        _userState = placemarks.first.administrativeArea;
        final currentState = (_userState ?? '').trim();
        _segmentService.onCustomEvent('Nearby Cafes Viewed', {
          'city': currentState.isEmpty ? 'unknown' : currentState,
        });
        _fbEventsService.onNearbyCafesViewed(
          city: currentState.isEmpty ? 'unknown' : currentState,
        );
        if (previousState.isNotEmpty &&
            currentState.isNotEmpty &&
            previousState.toLowerCase() != currentState.toLowerCase()) {
          _segmentService.onCustomEvent('City Changed', {
            'from_city': previousState,
            'to_city': currentState,
          });
          _fbEventsService.onCityChanged(
            fromCity: previousState,
            toCity: currentState,
          );
        }

        // Filter cafes based on state
        _applyCafeFilterAndRefresh();
      } else {}
    } finally {
      _isLocationFiltering.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Map with rounded top corners
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: SizedBox(
                height: size * 0.55,
                width: double.infinity,
                child: Stack(
                  children: [
                    Obx(
                      () => GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(20, 77),
                          zoom: 4,
                        ),
                        myLocationEnabled: _hasLocationPermission,
                        myLocationButtonEnabled: _hasLocationPermission,
                        markers: markers.toSet(),
                        polylines: polylines.toSet(),
                        onMapCreated: (ctrl) async {
                          _mapCtr = ctrl;
                          _mapReady = true;

                          // iOS: give the renderer a moment before styling
                          if (defaultTargetPlatform == TargetPlatform.iOS) {
                            await Future.delayed(
                              const Duration(milliseconds: 200),
                            );
                          }

                          try {
                            if (_mapStyle.isNotEmpty) {
                              await _mapCtr.setMapStyle(_mapStyle);
                            }
                          } catch (e) {
                            debugPrint('setMapStyle error: $e');
                          }

                          _tryPlayZoom();
                        },
                        zoomControlsEnabled: false,
                      ),
                    ),

                    // Search bar
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchCtl,
                          style: GoogleFonts.inter(color: Colors.white),
                          cursorColor: const Color(0xff00DC00),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            hintText: 'Search location',
                            hintStyle: GoogleFonts.inter(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onTap: () => Get.to(SearchResult()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Nearby Cafes Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCafeHeader(),
                    Expanded(
                      child: Obx(
                        () => _filteredCafes.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  reverse: true,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_userState != null)
                                        Text(
                                          'No cafes available in $_userState',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        )
                                      else
                                        AppLinearLoader(),
                                      const SizedBox(height: 8),
                                      if (_userState != null)
                                        GestureDetector(
                                          onTap: () {
                                            _showingAllCafes.value = true;
                                            _filteredCafes.assignAll(
                                              _cafeCtr.cybercafes
                                                  .cast<Map<String, dynamic>>(),
                                            );
                                            _refreshCafeMarkers();
                                          },
                                          child: Text(
                                            'Show all cafes',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xff00DC00),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : PageView.builder(
                                controller: _cafePageController,
                                padEnds: false,
                                onPageChanged: _focusCafeByIndex,
                                itemCount: _filteredCafes.length,
                                itemBuilder: (_, i) {
                                  final cafe = _filteredCafes[i];
                                  final imgs =
                                      (cafe['images'] as List?) ?? const [];
                                  final img = imgs.isEmpty
                                      ? 'https://next-level.gg/assets/cafes/11.jpg'
                                      : (imgs.first is Map &&
                                                (imgs.first as Map)['url'] !=
                                                    null
                                            ? (imgs.first as Map)['url']
                                                  as String
                                            : 'https://next-level.gg/assets/cafes/11.jpg');
                                  final pos = _latLngFromCafe(cafe);
                                  final id = '${cafe['id'] ?? cafe.hashCode}';
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: i == 0 ? 16 : 8,
                                      right: i == _filteredCafes.length - 1
                                          ? 16
                                          : 8,
                                    ),
                                    child: _buildCafeCard(
                                      id,
                                      pos,
                                      img,
                                      cafe,
                                      imgs,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeCard(
    String id,
    LatLng? pos, // <- nullable now
    String img,
    Map<String, dynamic> cafe,
    List<dynamic> images,
  ) {
    return BounceTap(
      onTap: () async {
        _selectedCafeId = id;
        _smoothMoveCamera(pos, zoom: 16);
        _refreshCafeMarkers();
        await Future.delayed(const Duration(milliseconds: 600));
        await Get.to(
          () => ArenaDetailView(
            images: images,
            title: cafe['cafe_name'] ?? 'Unknown Cafe',
            address: _formatAddress(cafe),
            openingHours: _formatOpeningHours(cafe),
            availableGames: cafe['available_games'] ?? ['N/A'],
            amenities: cafe['amenities'] ?? [],
            phone: cafe['phone'] ?? 'Phone not available',
            email: cafe['email'] ?? 'Email not available',
            ownerName: cafe['owner_name'] ?? 'Owner not available',
            reviews: cafe['reviews'] ?? ['Great place!'],
            vendorId: cafe['vendor_id'] ?? 0,
          ),
        );
      },
      child: Container(
        width: 330,
        height: 140, // a touch taller for breathing room
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image — fill the card precisely
            CachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              // Hint the cache with 2x widget size (optional)

              // memCacheWidth: 660,
              // memCacheHeight: 280,
              placeholder: (_, __) =>
                  const Center(child: RainbowGlowingLoader(size: 40)),
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

            // Subtle gradient for contrast (cheaper than full blur)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xCC000000), // ~80% black at bottom
                    const Color(0x66000000), // ~40%
                    const Color(0x00000000), // transparent
                  ],
                ),
              ),
            ),

            // Optional mild blur just for the bottom band (keep sigma low)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 53, // glassy bottom 40–60px
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 4,
                    sigmaY: 4,
                  ), // was 10 (heavier)
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Builder(
                  builder: (_) {
                    final bool isOpen = _isShopOpen(cafe);
                    final Color openColor = isOpen
                        ? const Color(0xff00DC00)
                        : Colors.red;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          toStartCase(
                            cafe['cafe_name']?.toString() ?? 'Unknown Cafe',
                          ),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Status · Distance · Duration
                        Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: openColor),
                            const SizedBox(width: 6),
                            Text(
                              isOpen ? 'Open' : 'Closed',
                              style: GoogleFonts.inter(
                                color: openColor,
                                fontSize: 12,
                              ),
                            ),

                            // separator
                            _miniSeparator(),

                            // Distance + duration (or placeholders)
                            FutureBuilder<Map<String, String>>(
                              future: _distanceFuture(id, pos),
                              builder: (_, snap) {
                                final dist = snap.data?['distance'] ?? '--';
                                final dur = snap.data?['duration'] ?? '--';
                                return Row(
                                  children: [
                                    Text(
                                      dist,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    _miniSeparator(),
                                    Text(
                                      dur,
                                      style: GoogleFonts.inter(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: pos == null
                                      ? null
                                      : () {
                                          final p = pos;
                                          _drawRoute(p);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff00DC00),
                                    disabledBackgroundColor: const Color(
                                      0xff00DC00,
                                    ).withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.directions_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Directions',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: pos == null
                                      ? null
                                      : () {
                                          final p = pos;
                                          _openExternalMaps(p);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.13,
                                    ),
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: 0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.13,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'View on maps',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      //
    );
  }

  Widget _miniSeparator() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      width: 1,
      height: 10,
      color: Colors.white.withValues(alpha: 0.35),
    ),
  );

  Widget _buildCafeHeader() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          children: [
            Text(
              _showingAllCafes.value
                  ? 'Showing All Cafes'
                  : (_userState != null
                        ? 'Cafes in $_userState'
                        : 'Nearby Cafes'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            if (_userState != null) ...[
              const SizedBox(width: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff00DC00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff00DC00)),
                  ),
                  child: Text(
                    _showingAllCafes.value
                        ? '${_filteredCafes.length} total'
                        : '${_filteredCafes.length} found',
                    style: GoogleFonts.inter(
                      color: const Color(0xff00DC00),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),

              Obx(
                () => GestureDetector(
                  onTap: () {
                    if (_showingAllCafes.value) {
                      // Switch back to filtered view
                      _showingAllCafes.value = false;
                      _applyCafeFilterAndRefresh();
                    } else {
                      // Show all cafes
                      _showingAllCafes.value = true;
                      _filteredCafes.assignAll(
                        _cafeCtr.cybercafes.cast<Map<String, dynamic>>(),
                      );
                      _refreshCafeMarkers();
                    }
                  },
                  child: Text(
                    _showingAllCafes.value ? 'Show local' : 'Show all',
                    style: GoogleFonts.inter(
                      color: const Color(0xff00DC00),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
