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
import 'package:hash/core/service/location_permission_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    hide NetworkProvider;
import 'package:hash/app/modules/arena/utils/arena_games_extractor.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/app/modules/arena/controllers/nearby_teammates_controller.dart';
import 'package:hash/app/modules/arena/models/nearby_teammate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import '../../../../utils/service.dart';
import '../../../../utils/widgets/loader.dart';
import 'arena_view_detailed.dart';

enum _DiscoveryMode { cafes, teammates }

class ArenaView extends StatefulWidget {
  const ArenaView({super.key});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  static const String _teammatesPromptDismissedKey =
      'arena_teammates_prompt_dismissed_v1';
  static const String _teammatesLocationVisibleKey =
      'arena_teammates_location_visible_v1';
  static const Duration _stateCacheTtl = Duration(minutes: 30);
  static final Map<String, String> _stateCache = <String, String>{};
  static final Map<String, DateTime> _stateCacheTime = <String, DateTime>{};

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  STATE                                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  final CybercafesController _cafeCtr = Get.put(
    CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
  );
  final NearbyTeammatesController _teammatesCtr = Get.put(
    NearbyTeammatesController(),
  );
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final LocationPermissionService _locationPermissionService =
      locator<LocationPermissionService>();
  final SharedPreferences _prefs = locator<SharedPreferences>();

  late GoogleMapController _mapCtr;
  late final loc.Location _loc = _locationPermissionService.location;
  StreamSubscription<loc.LocationData>? _locationSub;
  late final Worker _cafesWorker;
  late final Worker _teammatesWorker;
  bool _hasLocationPermission = false; // add

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final Rx<_DiscoveryMode> _discoveryMode = _DiscoveryMode.cafes.obs;

  late final String _gmapsKey = AppKeys.googleMapsApiKey;
  late final _polylinePoints = PolylinePoints(apiKey: _gmapsKey); // was ''

  final TextEditingController _searchCtl = TextEditingController();
  final PageController _cafePageController = PageController(
    viewportFraction: 0.9,
  );
  final PageController _teammatePageController = PageController(
    viewportFraction: 0.88,
  );
  Timer? _camDebounce;

  LatLng? _userLatLng;
  String? _selectedCafeId;
  String? _selectedTeammateId;
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

  bool _mapReady = false; // NEW
  bool _playedZoom = false; // NEW
  bool _mapDisposed = false;
  bool _teammatesPromptResolved = false;

  BitmapDescriptor? _markerUser,
      _markerCafe,
      _markerCafeHighlighted,
      _markerGamer,
      _markerGamerHighlighted;
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
    _teammatesWorker = ever<List<NearbyTeammate>>(
      _teammatesCtr.filteredTeammates,
      (_) {
        if (_discoveryMode.value == _DiscoveryMode.teammates) {
          _refreshTeammateMarkers();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Cached cafes may already be in the controller before this view
      // attaches its worker. Seed the UI immediately, then refine with
      // location/state once that async work completes.
      if (_cafeCtr.cybercafes.isNotEmpty) {
        _applyCafeFilterAndRefresh();
      }

      unawaited(_bootstrapArenaCafes());
    });
  }

  Future<void> _bootstrapArenaCafes() async {
    await _initLocation();
    if (!mounted) return;

    if (_cafeCtr.cybercafes.isEmpty && !_cafeCtr.isLoading.value) {
      await _cafeCtr.fetchCybercafes(forceRefresh: false);
    }
    if (!mounted) return;

    if (_userLatLng != null) {
      await _getUserStateAndFilterCafes();
    } else {
      _applyCafeFilterAndRefresh();
    }
  }

  @override
  void dispose() {
    final shouldDisposeMap = _mapReady;
    _mapDisposed = true;
    _mapReady = false;
    _locationSub?.cancel();
    _cafesWorker.dispose();
    _teammatesWorker.dispose();
    _searchCtl.dispose();
    _cafePageController.dispose();
    _teammatePageController.dispose();
    _camDebounce?.cancel();
    if (shouldDisposeMap) {
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
    _markerGamer = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueViolet,
    );
    _markerGamerHighlighted = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );

    if (!mounted) return;
    if (_mapReady && _mapStyle.isNotEmpty) {
      try {
        await _mapCtr.setMapStyle(_mapStyle);
      } catch (_) {}
    }
    _refreshActiveMarkers();
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LOCATION INIT                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _initLocation() async {
    try {
      final service = await _locationPermissionService.ensureServiceEnabled();
      if (!service) return;

      final perm = await _locationPermissionService.ensurePermission();
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
      unawaited(_loadTeammatesForCurrentLocation());
      _tryPlayZoom();

      // Optional: first valid update via stream
      _locationSub?.cancel();
      _locationSub = _loc.onLocationChanged.listen((d) {
        final la = d.latitude, lo = d.longitude;
        if (la != null && lo != null) {
          if (_userLatLng == null) {
            _userLatLng = LatLng(la, lo);
            unawaited(_loadTeammatesForCurrentLocation());
            _refreshActiveMarkers();
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
    if (!_mapReady || _mapDisposed || target == null) return;
    _camDebounce?.cancel();
    _camDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(
        _safeAnimateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: zoom),
          ),
        ),
      );
    });
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  GTA-STYLE ZOOM LOGIC                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _playZoomAnimation() async {
    if (_userLatLng == null || !_mapReady || _mapDisposed || !mounted) return;
    _playedZoom = true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!_mapReady || _mapDisposed || !mounted) return;
    }

    // start far away
    await _safeMoveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLatLng!, zoom: 4),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_mapReady || _mapDisposed || !mounted) return;

    // zoom mid-range
    await _safeAnimateCamera(CameraUpdate.zoomTo(9));
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_mapReady || _mapDisposed || !mounted) return;

    // final close-up
    await _safeAnimateCamera(CameraUpdate.zoomTo(15));
  }

  void _tryPlayZoom() {
    if (_mapReady && _userLatLng != null && !_playedZoom) {
      unawaited(_playZoomAnimation());
    }
  }

  Future<void> _safeMoveCamera(
    CameraUpdate update, {
    bool allowRetry = true,
  }) async {
    if (!_mapReady || _mapDisposed || !mounted) return;
    try {
      await _mapCtr.moveCamera(update);
    } on PlatformException catch (e) {
      if (allowRetry && e.code == 'channel-error') {
        await Future.delayed(const Duration(milliseconds: 250));
        if (!_mapReady || _mapDisposed || !mounted) return;
        try {
          await _mapCtr.moveCamera(update);
        } on PlatformException catch (_) {
          debugPrint('moveCamera channel unavailable after retry');
        }
      } else {
        debugPrint('moveCamera failed: ${e.code}');
      }
    } catch (e) {
      debugPrint('moveCamera failed: $e');
    }
  }

  Future<void> _safeAnimateCamera(
    CameraUpdate update, {
    bool allowRetry = true,
  }) async {
    if (!_mapReady || _mapDisposed || !mounted) return;
    try {
      await _mapCtr.animateCamera(update);
    } on PlatformException catch (e) {
      if (allowRetry && e.code == 'channel-error') {
        await Future.delayed(const Duration(milliseconds: 250));
        if (!_mapReady || _mapDisposed || !mounted) return;
        try {
          await _mapCtr.animateCamera(update);
        } on PlatformException catch (_) {
          debugPrint('animateCamera channel unavailable after retry');
        }
      } else {
        debugPrint('animateCamera failed: ${e.code}');
      }
    } catch (e) {
      debugPrint('animateCamera failed: $e');
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

  Future<void> _loadTeammatesForCurrentLocation() async {
    final position = _userLatLng;
    if (position == null) return;
    final isVisible = _prefs.getBool(_teammatesLocationVisibleKey) ?? true;
    _teammatesCtr.locationVisible.value = isVisible;
    await _teammatesCtr.loadNearby(position);
    if (!mounted || _discoveryMode.value != _DiscoveryMode.teammates) return;
    _refreshTeammateMarkers();
  }

  Future<bool> _ensureTeammatesPromptResolved() async {
    if (_teammatesPromptResolved) return true;

    final dontShowAgain = _prefs.getBool(_teammatesPromptDismissedKey) ?? false;
    if (dontShowAgain) {
      _teammatesPromptResolved = true;
      _teammatesCtr.locationVisible.value =
          _prefs.getBool(_teammatesLocationVisibleKey) ?? true;
      return true;
    }

    final position = _userLatLng;
    if (position == null) {
      Get.snackbar(
        'Location needed',
        'Enable GPS to find nearby gamers.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    bool dontShow = false;
    bool shareLocation = _prefs.getBool(_teammatesLocationVisibleKey) ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff0B0D0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Find your nearby gamer',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use your device GPS to discover gamers around you.',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xff00DC00),
                    title: Text(
                      'Show my location',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      shareLocation
                          ? 'Others can discover you nearby.'
                          : 'You stay hidden but can still discover others.',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                    value: shareLocation,
                    onChanged: (value) {
                      setDialogState(() => shareLocation = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xff00DC00),
                    checkColor: Colors.black,
                    title: Text(
                      "Don't show this again",
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    value: dontShow,
                    onChanged: (value) {
                      setDialogState(() => dontShow = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Not now',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00DC00),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      await _switchDiscoveryMode(_DiscoveryMode.cafes);
      return false;
    }

    await _prefs.setBool(_teammatesLocationVisibleKey, shareLocation);
    if (dontShow) {
      await _prefs.setBool(_teammatesPromptDismissedKey, true);
    }

    _teammatesPromptResolved = true;
    _teammatesCtr.locationVisible.value = shareLocation;
    await _teammatesCtr.setLocationVisibility(
      visible: shareLocation,
      userLocation: position,
    );
    return true;
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
    if (_discoveryMode.value != _DiscoveryMode.cafes) return;
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

  void _refreshActiveMarkers() {
    if (_discoveryMode.value == _DiscoveryMode.teammates) {
      _refreshTeammateMarkers();
    } else {
      _refreshCafeMarkers();
    }
  }

  void _refreshTeammateMarkers() {
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

    for (final teammate in _teammatesCtr.filteredTeammates) {
      final pos = LatLng(teammate.latitude, teammate.longitude);
      nextMarkers.add(
        Marker(
          markerId: MarkerId('teammate_${teammate.id}'),
          position: pos,
          icon: teammate.id == _selectedTeammateId
              ? (_markerGamerHighlighted ?? BitmapDescriptor.defaultMarker)
              : (_markerGamer ?? BitmapDescriptor.defaultMarker),
          infoWindow: InfoWindow(title: teammate.username),
          onTap: () {
            _selectedTeammateId = teammate.id;
            _smoothMoveCamera(pos, zoom: 16);
            _refreshTeammateMarkers();
            _showTeammateBottomSheet(teammate);
          },
        ),
      );
    }

    markers
      ..clear()
      ..addAll(nextMarkers);
  }

  Future<void> _switchDiscoveryMode(_DiscoveryMode mode) async {
    if (_discoveryMode.value == mode) return;
    _discoveryMode.value = mode;
    polylines.clear();

    if (mode == _DiscoveryMode.teammates) {
      final canProceed = await _ensureTeammatesPromptResolved();
      if (!canProceed) return;
      if (_teammatesCtr.teammates.isEmpty && _userLatLng != null) {
        unawaited(_loadTeammatesForCurrentLocation());
      }
      _refreshTeammateMarkers();
    } else {
      _refreshCafeMarkers();
    }
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
    await _safeAnimateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
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

      final cacheKey = _stateCacheKey(_userLatLng!);
      final cachedState = _stateCache[cacheKey];
      final cachedAt = _stateCacheTime[cacheKey];
      final hasFreshCache =
          cachedState != null &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _stateCacheTtl;
      if (hasFreshCache) {
        _applyResolvedUserState(cachedState);
        return;
      }

      try {
        final placemarks = await placemarkFromCoordinates(
          _userLatLng!.latitude,
          _userLatLng!.longitude,
        );

        if (placemarks.isNotEmpty) {
          final resolvedState =
              placemarks.first.administrativeArea?.trim() ?? '';
          if (resolvedState.isNotEmpty) {
            _stateCache[cacheKey] = resolvedState;
            _stateCacheTime[cacheKey] = DateTime.now();
            _applyResolvedUserState(resolvedState);
            return;
          }
        }
      } catch (_) {
        // Geocoding is not reliable enough to block cafe rendering.
      }

      _applyResolvedUserState(null);
    } finally {
      _isLocationFiltering.value = false;
    }
  }

  String _stateCacheKey(LatLng position) {
    return '${position.latitude.toStringAsFixed(3)},${position.longitude.toStringAsFixed(3)}';
  }

  void _applyResolvedUserState(String? state) {
    final previousState = (_userState ?? '').trim();
    _userState = state;
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
    _applyCafeFilterAndRefresh();
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
                          _mapDisposed = false;
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

                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildDiscoveryModeToggle(),
                    ),

                    Positioned(
                      top: 74,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Obx(
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: _discoveryMode.value == _DiscoveryMode.cafes
                                ? TextField(
                                    key: const ValueKey('cafe_search'),
                                    controller: _searchCtl,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    cursorColor: const Color(0xff00DC00),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                    ),
                                    onTap: () => Get.to(SearchResult()),
                                  )
                                : _buildTeammateFilterBar(),
                          ),
                        ),
                      ),
                    ),

                    Obx(
                      () => _discoveryMode.value == _DiscoveryMode.teammates
                          ? Positioned(
                              right: 16,
                              bottom: 18,
                              child: _buildFindSquadButton(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
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
                child: Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _discoveryMode.value == _DiscoveryMode.cafes
                        ? _buildCafeDiscoveryPanel()
                        : _buildTeammateDiscoveryPanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeDiscoveryPanel() {
    return Column(
      key: const ValueKey('cafes_panel'),
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
                          if (_cafeCtr.isLoading.value &&
                              _cafeCtr.cybercafes.isEmpty)
                            AppLinearLoader(),
                          if (!_cafeCtr.isLoading.value &&
                              _cafeCtr.cybercafes.isEmpty)
                            Text(
                              'Unable to load cafes right now',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          if (!_cafeCtr.isLoading.value &&
                              _cafeCtr.cybercafes.isNotEmpty &&
                              _userState != null)
                            Text(
                              'No cafes available in $_userState',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (!_cafeCtr.isLoading.value &&
                              _cafeCtr.cybercafes.isEmpty)
                            GestureDetector(
                              onTap: () {
                                _cafeCtr.fetchCybercafes(forceRefresh: true);
                              },
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xff00DC00),
                                ),
                              ),
                            ),
                          if (!_cafeCtr.isLoading.value &&
                              _cafeCtr.cybercafes.isNotEmpty &&
                              _userState != null)
                            GestureDetector(
                              onTap: () {
                                _showingAllCafes.value = true;
                                _filteredCafes.assignAll(
                                  _sortCafesByDistance(
                                    _cafeCtr.cybercafes
                                        .cast<Map<String, dynamic>>(),
                                  ),
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
                      final imgs = (cafe['images'] as List?) ?? const [];
                      final img = imgs.isEmpty
                          ? 'https://next-level.gg/assets/cafes/11.jpg'
                          : (imgs.first is Map &&
                                    (imgs.first as Map)['url'] != null
                                ? (imgs.first as Map)['url'] as String
                                : 'https://next-level.gg/assets/cafes/11.jpg');
                      final pos = _latLngFromCafe(cafe);
                      final id = '${cafe['id'] ?? cafe.hashCode}';
                      return Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 16 : 8,
                          right: i == _filteredCafes.length - 1 ? 16 : 8,
                        ),
                        child: _buildCafeCard(id, pos, img, cafe, imgs),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeammateDiscoveryPanel() {
    return Column(
      key: const ValueKey('teammates_panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeammateHeader(),
        Expanded(
          child: Obx(() {
            if (_teammatesCtr.isLoading.value &&
                _teammatesCtr.filteredTeammates.isEmpty) {
              return const Center(child: RainbowGlowingLoader(size: 46));
            }
            if (_userLatLng == null) {
              return _buildTeammateEmptyState(
                'Enable location to discover gamers nearby',
              );
            }
            if (_teammatesCtr.filteredTeammates.isEmpty) {
              return _buildTeammateEmptyState(
                'No teammates match your filters',
              );
            }
            return PageView.builder(
              controller: _teammatePageController,
              padEnds: false,
              onPageChanged: _focusTeammateByIndex,
              itemCount: _teammatesCtr.filteredTeammates.length,
              itemBuilder: (_, index) {
                final teammate = _teammatesCtr.filteredTeammates[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == _teammatesCtr.filteredTeammates.length - 1
                        ? 16
                        : 8,
                  ),
                  child: _buildTeammateCard(teammate),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiscoveryModeToggle() {
    return Obx(
      () => Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            _buildModeSegment(
              label: 'Cafes',
              icon: Icons.local_cafe_outlined,
              mode: _DiscoveryMode.cafes,
            ),
            _buildModeSegment(
              label: 'Teammates',
              icon: Icons.sports_esports_outlined,
              mode: _DiscoveryMode.teammates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegment({
    required String label,
    required IconData icon,
    required _DiscoveryMode mode,
  }) {
    final selected = _discoveryMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          unawaited(_switchDiscoveryMode(mode));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xff00DC00).withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeammateFilterBar() {
    return SizedBox(
      key: const ValueKey('teammate_filters'),
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.tune, color: Color(0xff00DC00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => Text(
                '${_teammatesCtr.filteredTeammates.length} gamers nearby',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _showTeammateFiltersSheet,
            child: Text(
              'Filters',
              style: GoogleFonts.inter(
                color: const Color(0xff00DC00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildFindSquadButton() {
    return BounceTap(
      onTap: _handleFindSquad,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff00DC00),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00DC00).withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2_outlined, color: Colors.black, size: 19),
            const SizedBox(width: 8),
            Text(
              'Find Squad',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeammateHeader() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          children: [
            Text(
              'Nearby Teammates',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff00DC00).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff00DC00)),
              ),
              child: Text(
                '${_teammatesCtr.filteredTeammates.length} found',
                style: GoogleFonts.inter(
                  color: const Color(0xff00DC00),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeammateEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              color: Colors.white.withValues(alpha: 0.45),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _teammatesCtr.clearFilters();
                unawaited(_loadTeammatesForCurrentLocation());
              },
              child: Text(
                'Refresh',
                style: GoogleFonts.inter(color: const Color(0xff00DC00)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeammateCard(NearbyTeammate teammate) {
    final pos = LatLng(teammate.latitude, teammate.longitude);
    return BounceTap(
      onTap: () {
        _selectedTeammateId = teammate.id;
        _smoothMoveCamera(pos, zoom: 16);
        _refreshTeammateMarkers();
        _showTeammateBottomSheet(teammate);
      },
      child: Container(
        width: 330,
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff070907),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xff00DC00).withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00DC00).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(teammate.avatar, size: 62),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teammate.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusDot(teammate.online),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${teammate.compatibilityScore.round()}% compatibility',
                    style: GoogleFonts.inter(
                      color: const Color(0xff00DC00),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${teammate.rank} • ${teammate.playStyle}',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    teammate.games.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String url, {double size = 58}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff00DC00), width: 2),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => const RainbowGlowingLoader(size: 24),
        errorWidget: (_, _, _) =>
            const Icon(Icons.person, color: Colors.white70),
      ),
    );
  }

  Widget _statusDot(bool online) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          color: online ? const Color(0xff00DC00) : Colors.white38,
          size: 9,
        ),
        const SizedBox(width: 5),
        Text(
          online ? 'Online' : 'Away',
          style: GoogleFonts.inter(
            color: online ? const Color(0xff00DC00) : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _focusTeammateByIndex(int index) {
    if (index < 0 || index >= _teammatesCtr.filteredTeammates.length) return;
    final teammate = _teammatesCtr.filteredTeammates[index];
    _selectedTeammateId = teammate.id;
    _smoothMoveCamera(LatLng(teammate.latitude, teammate.longitude), zoom: 16);
    _refreshTeammateMarkers();
  }

  void _handleFindSquad() {
    final squad = _teammatesCtr.findSquad();
    if (squad.isEmpty) {
      Get.snackbar('Find Squad', 'No compatible teammates found');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff080A08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Squad Match',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...squad.map(
                  (teammate) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _buildAvatar(teammate.avatar, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            teammate.username,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${teammate.compatibilityScore.round()}%',
                          style: GoogleFonts.inter(
                            color: const Color(0xff00DC00),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00DC00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Invite Squad'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTeammateBottomSheet(NearbyTeammate teammate) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff080A08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(teammate.avatar, size: 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teammate.username,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusDot(teammate.online),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _teammateDetailRow(
                  'Compatibility',
                  '${teammate.compatibilityScore.round()}%',
                ),
                _teammateDetailRow('Rank', teammate.rank),
                _teammateDetailRow('Games', teammate.games.join(', ')),
                _teammateDetailRow('Language', teammate.languages.join(', ')),
                _teammateDetailRow('Mic', teammate.micEnabled ? 'Yes' : 'No'),
                _teammateDetailRow('Play style', teammate.playStyle),
                _teammateDetailRow('Online', teammate.online ? 'Yes' : 'No'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff00DC00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Invite'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openTeammateChat(teammate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Profile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTeammateChat(NearbyTeammate teammate) async {
    final chatService = Get.isRegistered<ChatService>()
        ? Get.find<ChatService>()
        : Get.put(ChatService(), permanent: true);
    try {
      final roomId = await chatService.getOrCreateDirectRoom(
        otherUser: ChatUserModel(
          uid: teammate.id,
          displayName: teammate.username,
          username: teammate.username.toLowerCase().replaceAll(' ', ''),
          email: '',
          phoneNumber: '',
          photoUrl: teammate.avatar,
          isOnline: teammate.online,
          updatedAt: DateTime.now(),
          lastSeenAt: null,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Get.to(() => ChatRoomView(roomId: roomId));
    } catch (_) {
      Get.snackbar(
        'Chat unavailable',
        'Could not open chat with ${teammate.username}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _teammateDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTeammateFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff080A08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Obx(
            () => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Teammate Filters',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _teammatesCtr.clearFilters,
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            color: const Color(0xff00DC00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _filterChoices(
                    title: 'Game',
                    values: _teammatesCtr.availableGames,
                    selected: _teammatesCtr.selectedGame.value,
                    onSelected: (value) {
                      _teammatesCtr.selectedGame.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                  _filterChoices(
                    title: 'Rank',
                    values: _teammatesCtr.availableRanks,
                    selected: _teammatesCtr.selectedRank.value,
                    onSelected: (value) {
                      _teammatesCtr.selectedRank.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                  _filterChoices(
                    title: 'Language',
                    values: _teammatesCtr.availableLanguages,
                    selected: _teammatesCtr.selectedLanguage.value,
                    onSelected: (value) {
                      _teammatesCtr.selectedLanguage.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                  _filterChoices(
                    title: 'Play style',
                    values: _teammatesCtr.availablePlayStyles,
                    selected: _teammatesCtr.selectedPlayStyle.value,
                    onSelected: (value) {
                      _teammatesCtr.selectedPlayStyle.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xff00DC00),
                    title: Text(
                      'Mic required',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    value: _teammatesCtr.micRequired.value,
                    onChanged: (value) {
                      _teammatesCtr.micRequired.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compatibility score: ${_teammatesCtr.minimumCompatibility.value.round()}%+',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  Slider(
                    value: _teammatesCtr.minimumCompatibility.value,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: const Color(0xff00DC00),
                    inactiveColor: Colors.white.withValues(alpha: 0.18),
                    onChanged: (value) {
                      _teammatesCtr.minimumCompatibility.value = value;
                      _teammatesCtr.applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterChoices({
    required String title,
    required List<String> values,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(
                label: 'Any',
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              ...values.map(
                (value) => _filterChip(
                  label: value,
                  selected: selected == value,
                  onTap: () => onSelected(value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xff00DC00),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: selected
            ? const Color(0xff00DC00)
            : Colors.white.withValues(alpha: 0.14),
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
            availableGames: extractArenaAvailableGames(cafe),
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
              placeholder: (_, _) =>
                  const Center(child: RainbowGlowingLoader(size: 40)),
              errorWidget: (_, _, _) => Container(
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
