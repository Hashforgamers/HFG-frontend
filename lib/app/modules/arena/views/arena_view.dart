// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/views/search_result.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
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

  late GoogleMapController _mapCtr;
  final loc.Location _loc = loc.Location();
  bool _hasLocationPermission = false; // add

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  final _polylinePoints = PolylinePoints(apiKey: _gmapsKey); // was ''

  final TextEditingController _searchCtl = TextEditingController();
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

  /// ⚠️  Replace with build-time env variable or secure storage
  static const _gmapsKey = 'AIzaSyAIeaszJ60ZcjL9hNYpsQ_JD8w8J2vnmuQ';
  bool _mapReady = false; // NEW
  bool _playedZoom = false; // NEW

  BitmapDescriptor? _markerUser, _markerCafe, _markerCafeHighlighted;
  String _normState(String? s) {
    if (s == null) return '';
    final t = s.trim().toLowerCase();
    if (t == 'mh' || t == 'maharastra') return 'maharashtra';
    return t;
  }

  void _filterCafesByState() {
    final user = _normState(_userState);
    if (user.isEmpty) {
      _filteredCafes.assignAll(
        _cafeCtr.cybercafes.cast<Map<String, dynamic>>(),
      );
      return;
    }
    final filtered = _cafeCtr.cybercafes.where((c) {
      final cafeState = _normState(c['address']?['state']);
      return cafeState == user;
    }).toList();
    _filteredCafes.assignAll(filtered.cast<Map<String, dynamic>>());
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LIFECYCLE                                                                */
  /* ────────────────────────────────────────────────────────────────────────── */

  @override
  void initState() {
    super.initState();
    _loadAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initLocation();
      await _cafeCtr.fetchCybercafes();
      await _getUserStateAndFilterCafes();
      _addUserMarker();
      _refreshCafeMarkers();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _camDebounce?.cancel();
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
      _loc.onLocationChanged.listen((d) {
        final la = d.latitude, lo = d.longitude;
        if (la != null && lo != null) {
          if (_userLatLng == null) {
            _userLatLng = LatLng(la, lo);
            _addUserMarker();
            _tryPlayZoom();
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
    if (!_mapReady) return; // add this
    _camDebounce?.cancel();
    _camDebounce = Timer(const Duration(milliseconds: 280), () {
      _mapCtr.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target!, zoom: zoom),
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
    // Check for shop_open field (most common)
    final shopOpen = cafe['shop_open'];
    if (shopOpen != null) {
      return shopOpen == true || shopOpen == 'true' || shopOpen == 1;
    }

    // Check for status field
    final status = cafe['status'];
    if (status != null) {
      // For pending_verification status, determine based on opening hours
      if (status == 'pending_verification') {
        return _isCurrentlyOpen(cafe);
      }
      return status == 'active' ||
          status == 'verified' ||
          status == 'open' ||
          status == 'operational';
    }

    // Check for is_open field
    final isOpen = cafe['is_open'];
    if (isOpen != null) {
      return isOpen == true || isOpen == 'true' || isOpen == 1;
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
    if (_userLatLng == null) return;
    markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: _userLatLng!,
        icon: _markerUser ?? BitmapDescriptor.defaultMarker,
      ),
    );
  }

  void _refreshCafeMarkers() {
    markers.removeWhere((m) => m.markerId.value.startsWith('cafe_'));
    for (final cafe in _filteredCafes) {
      final id = '${cafe['id'] ?? cafe.hashCode}';
      final pos = _latLngFromCafe(cafe);
      if (pos == null) continue; // skip invalid
      markers.add(
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
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  DISTANCE + DURATION (Directions API)                                     */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<Map<String, String>> _distanceInfo(LatLng dest, String id) async {
    const fallback = {'distance': '--', 'duration': '--'};

    if (_userLatLng == null) return fallback;

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
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
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

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  ROUTE DRAWING                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _drawRoute(LatLng dest) async {
    if (_userLatLng == null) return;

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
          color: const Color(0xff338125),
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
      _filteredCafes.assignAll(
        _cafeCtr.cybercafes.cast<Map<String, dynamic>>(),
      );
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
        _userState = placemarks.first.administrativeArea;

        // Filter cafes based on state
        _filterCafesByState();
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
        child: Obx(() {
          return Column(
            children: [
              // Map with rounded top corners
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: SizedBox(
                  height: size * 0.51,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(20, 77),
                          zoom: 4,
                        ),
                        myLocationEnabled: _hasLocationPermission, // was: true
                        myLocationButtonEnabled:
                            _hasLocationPermission, // add this
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
                            debugPrint(
                              'setMapStyle error: $e',
                            ); // helps catch invalid JSON
                          }

                          _tryPlayZoom();
                        },
                        zoomControlsEnabled: false,
                      ),

                      // Search bar
                      Positioned(
                        top: 20,
                        left: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchCtl,
                            style: GoogleFonts.inter(color: Colors.white),
                            cursorColor: const Color(0xff338125),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              hintText: 'Search location',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.white70,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            // onSubmitted: (_) => _searchAndGo(),
                            onTap: () {
                              Get.to(SearchResult());
                            },
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          RainbowLoadingBar(),
                                        const SizedBox(height: 8),
                                        if (_userState != null)
                                          GestureDetector(
                                            onTap: () {
                                              _showingAllCafes.value = true;
                                              _filteredCafes.assignAll(
                                                _cafeCtr.cybercafes
                                                    .cast<
                                                      Map<String, dynamic>
                                                    >(),
                                              );
                                            },
                                            child: Text(
                                              'Show all cafes',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: const Color(0xff338125),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 20),
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
                                    final pos = _latLngFromCafe(
                                      cafe,
                                    ); // safe now
                                    final id = '${cafe['id'] ?? cafe.hashCode}';
                                    return _buildCafeCard(
                                      id,
                                      pos,
                                      img,
                                      cafe,
                                      imgs,
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
          );
        }),
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
    return GestureDetector(
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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              memCacheWidth: 660,
              memCacheHeight: 280,
              placeholder: (_, __) => const Center(child: RainbowGlowingLoader(size: 40)),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
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
              top: 84, // glassy bottom 40–60px
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // was 10 (heavier)
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Builder(
                  builder: (_) {
                    final bool isOpen = _isShopOpen(cafe);
                    final Color openColor = isOpen ? Colors.green : Colors.red;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          toStartCase(cafe['cafe_name']?.toString() ?? 'Unknown Cafe'),
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
                              style: GoogleFonts.inter(color: openColor, fontSize: 12),
                            ),

                            // separator
                            _miniSeparator(),

                            // Distance + duration (or placeholders)
                            FutureBuilder<Map<String, String>>(
                              future: pos == null
                                  ? Future.value({
                                      'distance': '--',
                                      'duration': '--',
                                    })
                                  : _distanceInfo(pos, id),
                              builder: (_, snap) {
                                final dist = snap.data?['distance'] ?? '--';
                                final dur  = snap.data?['duration'] ?? '--';
                                return Row(
                                  children: [
                                    Text(dist, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                                    _miniSeparator(),
                                    Text(dur,  style: GoogleFonts.inter(color: Colors.grey,  fontSize: 12)),
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
                                  onPressed: (pos == null) ? null : () => _drawRoute(pos!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff338125),
                                    disabledBackgroundColor: const Color(0xff338125).withOpacity(0.35),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.directions_outlined, color: Colors.white, size: 18),
                                  label: Text(
                                    'Directions',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: (pos == null) ? null : () => _openExternalMaps(pos!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.13),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.white.withOpacity(0.13)),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                                  label: Text(
                                    'View on maps',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
        ),)


//
    );
  }
  Widget _miniSeparator() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(width: 1, height: 10, color: Colors.white.withOpacity(0.35)),
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
                    color: const Color(0xff338125).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff338125)),
                  ),
                  child: Text(
                    _showingAllCafes.value
                        ? '${_filteredCafes.length} total'
                        : '${_filteredCafes.length} found',
                    style: GoogleFonts.inter(
                      color: const Color(0xff338125),
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
                      _filterCafesByState();
                    } else {
                      // Show all cafes
                      _showingAllCafes.value = true;
                      _filteredCafes.assignAll(
                        _cafeCtr.cybercafes.cast<Map<String, dynamic>>(),
                      );
                    }
                  },
                  child: Text(
                    _showingAllCafes.value ? 'Show local' : 'Show all',
                    style: GoogleFonts.inter(
                      color: const Color(0xff338125),
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
