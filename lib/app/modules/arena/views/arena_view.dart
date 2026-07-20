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
import 'package:hash/app/modules/arena/services/nearby_player_location_service.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_home_view.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
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
  static const Duration _stateCacheTtl = Duration(minutes: 30);
  static final Map<String, String> _stateCache = <String, String>{};
  static final Map<String, DateTime> _stateCacheTime = <String, DateTime>{};

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  STATE                                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  final CybercafesController _cafeCtr = Get.put(
    CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
  );
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final LocationPermissionService _locationPermissionService =
      locator<LocationPermissionService>();
  final NearbyPlayerLocationService _nearbyLocationService =
      NearbyPlayerLocationService();

  late GoogleMapController _mapCtr;
  late final loc.Location _loc = _locationPermissionService.location;
  StreamSubscription<loc.LocationData>? _locationSub;
  late final Worker _cafesWorker;
  bool _hasLocationPermission = false; // add

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  late final String _gmapsKey = AppKeys.googleMapsApiKey;
  late final _polylinePoints = PolylinePoints(apiKey: _gmapsKey); // was ''

  final PageController _cafePageController = PageController(
    viewportFraction: 0.9,
  );
  Timer? _camDebounce;

  LatLng? _userLatLng;
  String? _selectedCafeId;
  String _mapStyle = '';
  final List<Map<String, dynamic>> _nearbyPlayers = [];
  bool _showPlayers = false;
  bool _isLoadingPlayers = false;
  String? _playersError;
  double _mapZoom = 15;
  bool _isLocationSharingEnabled = false;
  bool _isUpdatingLocationSharing = false;
  DateTime? _lastLocationPublishAt;

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
    unawaited(_loadLocationSharingPreference());
    _cafesWorker = ever<List<dynamic>>(_cafeCtr.cybercafes, (_) {
      _applyCafeFilterAndRefresh();
    });
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
    _cafePageController.dispose();
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
      unawaited(_publishLocationIfNeeded(force: true).catchError((_) {}));
      unawaited(_fetchNearbyPlayers());
      _tryPlayZoom();

      // Optional: first valid update via stream
      _locationSub?.cancel();
      _locationSub = _loc.onLocationChanged.listen((d) {
        final la = d.latitude, lo = d.longitude;
        if (la != null && lo != null) {
          final wasMissingLocation = _userLatLng == null;
          _userLatLng = LatLng(la, lo);
          unawaited(_publishLocationIfNeeded().catchError((_) {}));
          if (wasMissingLocation) {
            _addUserMarker();
            _tryPlayZoom();
          }
        }
      });
    } catch (_) {
      /* swallow */
    }
  }

  Future<void> _fetchNearbyPlayers() async {
    final origin = _userLatLng;
    if (origin == null || _isLoadingPlayers) return;
    if (mounted) {
      setState(() {
        _isLoadingPlayers = true;
        _playersError = null;
      });
    }
    try {
      final players = await _nearbyLocationService.fetchNearbyPlayers(
        latitude: origin.latitude,
        longitude: origin.longitude,
      );
      if (!mounted) return;
      setState(() {
        _nearbyPlayers
          ..clear()
          ..addAll(players);
      });
      _refreshCafeMarkers();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _playersError = 'Nearby players are unavailable right now.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingPlayers = false);
    }
  }

  Future<void> _loadLocationSharingPreference() async {
    final enabled = await _nearbyLocationService.isSharingEnabled();
    if (!mounted) return;
    setState(() => _isLocationSharingEnabled = enabled);
    if (enabled) {
      unawaited(_publishLocationIfNeeded(force: true).catchError((_) {}));
    }
  }

  Future<void> _publishLocationIfNeeded({bool force = false}) async {
    if (!_isLocationSharingEnabled) return;
    final position = _userLatLng;
    if (position == null) return;
    final lastPublish = _lastLocationPublishAt;
    if (!force &&
        lastPublish != null &&
        DateTime.now().difference(lastPublish) < const Duration(minutes: 2)) {
      return;
    }
    await _nearbyLocationService.publishLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    _lastLocationPublishAt = DateTime.now();
  }

  Future<void> _toggleLocationSharing() async {
    if (_isUpdatingLocationSharing) return;
    final nextValue = !_isLocationSharingEnabled;
    setState(() => _isUpdatingLocationSharing = true);
    try {
      await _nearbyLocationService.setSharingEnabled(nextValue);
      if (mounted) {
        setState(() => _isLocationSharingEnabled = nextValue);
      }
      if (nextValue) {
        await _publishLocationIfNeeded(force: true);
      } else {
        _lastLocationPublishAt = null;
      }
      if (mounted) {
        Get.snackbar(
          nextValue ? 'Location visible' : 'Location hidden',
          nextValue
              ? 'Nearby players can now discover your approximate location.'
              : 'Your location is no longer shared with nearby players.',
        );
      }
    } catch (_) {
      if (nextValue) {
        await _nearbyLocationService.setSharingEnabled(false);
        if (mounted) setState(() => _isLocationSharingEnabled = false);
      }
      if (mounted) {
        Get.snackbar(
          'Location sharing',
          'Unable to update your visibility right now.',
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingLocationSharing = false);
    }
  }

  LatLng? _latLngFromPlayer(Map<String, dynamic> player) {
    final location = player['approximate_location'] ?? player['location'];
    if (location is! Map) return null;
    final lat = double.tryParse('${location['latitude']}');
    final lng = double.tryParse('${location['longitude']}');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Set<Heatmap> get _playerHeatmaps {
    if (!_showPlayers) return const <Heatmap>{};
    final points = _nearbyPlayers
        .map((player) {
          final position = _latLngFromPlayer(player);
          if (position == null) return null;
          final rawWeight =
              player['activity_weight'] ??
              player['activity_score'] ??
              (player['is_online'] == true ? 1.5 : 0.75);
          final weight = rawWeight is num
              ? rawWeight.toDouble().clamp(0.25, 3.0).toDouble()
              : 1.0;
          return WeightedLatLng(position, weight: weight);
        })
        .whereType<WeightedLatLng>()
        .toList();
    if (points.isEmpty) return const <Heatmap>{};
    return {
      Heatmap(
        heatmapId: const HeatmapId('nearby_player_activity'),
        data: points,
        radius: const HeatmapRadius.fromPixels(54),
        opacity: 0.72,
        maxIntensity: 3,
        gradient: const HeatmapGradient([
          HeatmapGradientColor(Color(0x3300DC00), 0.15),
          HeatmapGradientColor(Color(0xCC00DC00), 0.38),
          HeatmapGradientColor(Color(0xFFFFD600), 0.68),
          HeatmapGradientColor(Color(0xFFFF3D3D), 1),
        ]),
      ),
    };
  }

  Future<void> _connectWithPlayer(Map<String, dynamic> player) async {
    final roomId = await _roomForPlayer(player);
    if (roomId == null) return;
    Get.to(() => ChatRoomView(roomId: roomId));
  }

  Future<String?> _roomForPlayer(Map<String, dynamic> player) async {
    final uid = (player['firebase_uid'] ?? player['uid'] ?? '').toString();
    if (uid.isEmpty) {
      Get.snackbar('Connect', 'This player is not available for chat yet.');
      return null;
    }
    final user = ChatUserModel.fromMap({...player, 'uid': uid});
    final chat = Get.isRegistered<ChatService>()
        ? Get.find<ChatService>()
        : Get.put(ChatService(), permanent: true);
    final roomId = await chat.getOrCreateDirectRoom(otherUser: user);
    return roomId;
  }

  Future<void> _invitePlayerToCafe(Map<String, dynamic> player) async {
    final cafes = _sortCafesByDistance(_filteredCafes.toList());
    if (cafes.isEmpty) {
      Get.snackbar(
        'Cafe invite',
        'No nearby cafes are available to invite to.',
      );
      return;
    }
    final cafe = await Get.bottomSheet<Map<String, dynamic>>(
      SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: const BoxDecoration(
            color: Color(0xff121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Meet at a cafe',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: cafes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = cafes[index];
                    return ListTile(
                      onTap: () => Get.back(result: item),
                      tileColor: const Color(0xff1A1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xff00DC00),
                      ),
                      title: Text(
                        (item['cafe_name'] ?? 'Gaming cafe').toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _formatAddress(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
    if (cafe == null) return;
    final roomId = await _roomForPlayer(player);
    if (roomId == null) return;
    final name = (cafe['cafe_name'] ?? 'Gaming cafe').toString();
    final position = _latLngFromCafe(cafe);
    final mapsLink = position == null
        ? ''
        : ' https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final chat = Get.find<ChatService>();
    await chat.sendTextMessage(
      roomId: roomId,
      text: '🎮 Want to play at $name? ${_formatAddress(cafe)}$mapsLink',
    );
    Get.to(() => ChatRoomView(roomId: roomId));
  }

  Future<void> _invitePlayerToTournament(Map<String, dynamic> player) async {
    try {
      final page = await CommunityApi().listTournaments(
        view: 'upcoming',
        perPage: 30,
        sort: 'soonest',
      );
      if (page.items.isEmpty) {
        Get.to(() => const TournamentsHomeView());
        return;
      }
      final tournament = await Get.bottomSheet(
        SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 540),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xff121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Invite to a tournament',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = page.items[index];
                      return ListTile(
                        onTap: () => Get.back(result: item),
                        tileColor: const Color(0xff1A1A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xff00DC00),
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.game,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        isScrollControlled: true,
      );
      if (tournament == null) return;
      final roomId = await _roomForPlayer(player);
      if (roomId == null) return;
      final chat = Get.find<ChatService>();
      await chat.sendTextMessage(
        roomId: roomId,
        text:
            '🏆 I challenge you to join “${tournament.title}” (${tournament.game}). Open Tournaments in Hash to join me!',
      );
      Get.to(() => ChatRoomView(roomId: roomId));
    } catch (_) {
      Get.snackbar(
        'Tournament invite',
        'Unable to load tournaments right now.',
      );
    }
  }

  void _showPlayerActions(Map<String, dynamic> player) {
    final name = (player['display_name'] ?? player['username'] ?? 'Player')
        .toString();
    final games = (player['games'] as List?)?.join(', ') ?? 'Open to play';
    Get.bottomSheet(
      SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xff121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  games,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    unawaited(_connectWithPlayer(player));
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message player'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00DC00),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          unawaited(_invitePlayerToCafe(player));
                        },
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Meet at cafe'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xff1A1A1A),
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          minimumSize: const Size.fromHeight(46),
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          unawaited(_invitePlayerToTournament(player));
                        },
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('Tournament'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xff1A1A1A),
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          minimumSize: const Size.fromHeight(46),
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
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
    if (_showPlayers && _mapZoom >= 14) {
      for (final player in _nearbyPlayers) {
        final id =
            '${player['user_id'] ?? player['firebase_uid'] ?? player.hashCode}';
        final pos = _latLngFromPlayer(player);
        if (pos == null) continue;
        nextMarkers.add(
          Marker(
            markerId: MarkerId('player_$id'),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: (player['display_name'] ?? player['username'] ?? 'Player')
                  .toString(),
              snippet: player['is_online'] == true ? 'Online now' : 'Nearby',
            ),
            onTap: () => _showPlayerActions(player),
          ),
        );
      }
    } else {
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
    final mapHeight = (size * 0.48).clamp(300.0, 430.0);
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
                height: mapHeight,
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
                        heatmaps: _playerHeatmaps,
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
                        onCameraMove: (position) {
                          _mapZoom = position.zoom;
                        },
                        onCameraIdle: _refreshCafeMarkers,
                      ),
                    ),

                    // Search bar
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Get.to(SearchResult()),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xE6111111),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white70,
                                  size: 23,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Search cafes or locations',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 88,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xE6111111),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _mapModeButton(
                              label: 'Cafes',
                              icon: Icons.sports_esports_rounded,
                              selected: !_showPlayers,
                              onTap: () {
                                setState(() => _showPlayers = false);
                                _refreshCafeMarkers();
                              },
                            ),
                            _mapModeButton(
                              label: 'Players',
                              icon: Icons.people_alt_rounded,
                              selected: _showPlayers,
                              onTap: () {
                                setState(() => _showPlayers = true);
                                _refreshCafeMarkers();
                                unawaited(_fetchNearbyPlayers());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showPlayers)
                      Positioned(
                        top: 143,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE6111111),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff00DC00),
                                      Color(0xffFFD600),
                                      Color(0xffFF3D3D),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _mapZoom < 14
                                    ? 'Zoom in to see players'
                                    : 'Nearby activity',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                    if (_showPlayers)
                      _buildPlayersHeader()
                    else
                      _buildCafeHeader(),
                    Expanded(
                      child: _showPlayers
                          ? _buildNearbyPlayersList()
                          : Obx(
                              () => _filteredCafes.isEmpty
                                  ? Center(
                                      child: SingleChildScrollView(
                                        reverse: true,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                _cafeCtr
                                                    .cybercafes
                                                    .isNotEmpty &&
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
                                                  _cafeCtr.fetchCybercafes(
                                                    forceRefresh: true,
                                                  );
                                                },
                                                child: Text(
                                                  'Retry',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: const Color(
                                                      0xff00DC00,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (!_cafeCtr.isLoading.value &&
                                                _cafeCtr
                                                    .cybercafes
                                                    .isNotEmpty &&
                                                _userState != null)
                                              GestureDetector(
                                                onTap: () {
                                                  _showingAllCafes.value = true;
                                                  _filteredCafes.assignAll(
                                                    _sortCafesByDistance(
                                                      _cafeCtr.cybercafes
                                                          .cast<
                                                            Map<String, dynamic>
                                                          >(),
                                                    ),
                                                  );
                                                  _refreshCafeMarkers();
                                                },
                                                child: Text(
                                                  'Show all cafes',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: const Color(
                                                      0xff00DC00,
                                                    ),
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
                                            (cafe['images'] as List?) ??
                                            const [];
                                        final img = imgs.isEmpty
                                            ? 'https://next-level.gg/assets/cafes/11.jpg'
                                            : (imgs.first is Map &&
                                                      (imgs.first
                                                              as Map)['url'] !=
                                                          null
                                                  ? (imgs.first as Map)['url']
                                                        as String
                                                  : 'https://next-level.gg/assets/cafes/11.jpg');
                                        final pos = _latLngFromCafe(cafe);
                                        final id =
                                            '${cafe['id'] ?? cafe.hashCode}';
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            left: i == 0 ? 16 : 8,
                                            right:
                                                i == _filteredCafes.length - 1
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

  Widget _mapModeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff00DC00) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(
            'Players near you',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff00DC00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_nearbyPlayers.length} nearby',
              style: GoogleFonts.inter(
                color: const Color(0xff00DC00),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _isUpdatingLocationSharing ? null : _toggleLocationSharing,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _isLocationSharingEnabled
                    ? const Color(0xff00DC00).withValues(alpha: 0.14)
                    : const Color(0xff181818),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLocationSharingEnabled
                      ? const Color(0xff00DC00).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLocationSharingEnabled
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 14,
                    color: _isLocationSharingEnabled
                        ? const Color(0xff00DC00)
                        : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isLocationSharingEnabled ? 'Visible' : 'Hidden',
                    style: GoogleFonts.inter(
                      color: _isLocationSharingEnabled
                          ? const Color(0xff00DC00)
                          : Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlayersList() {
    if (_isLoadingPlayers && _nearbyPlayers.isEmpty) {
      return const Center(child: AppLinearLoader());
    }
    if (_nearbyPlayers.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.group_off_rounded,
                  color: Colors.white38,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  _playersError ?? 'No discoverable players nearby yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Players appear only when they enable nearby discovery.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _fetchNearbyPlayers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh nearby players'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff00DC00),
                    backgroundColor: const Color(
                      0xff00DC00,
                    ).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _nearbyPlayers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final player = _nearbyPlayers[index];
        final name = (player['display_name'] ?? player['username'] ?? 'Player')
            .toString();
        final distance = player['distance_km'];
        return ListTile(
          onTap: () => _showPlayerActions(player),
          tileColor: const Color(0xff151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xff242424),
            backgroundImage: (player['photo_url'] ?? '').toString().isNotEmpty
                ? CachedNetworkImageProvider(player['photo_url'].toString())
                : null,
            child: (player['photo_url'] ?? '').toString().isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white54)
                : null,
          ),
          title: Text(
            name,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            distance == null ? 'Nearby player' : '${distance} km away',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white38,
          ),
        );
      },
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
