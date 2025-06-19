import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'arena_view_detailed.dart';
import 'add_cafe_screen.dart';

class ArenaView extends StatefulWidget {
  const ArenaView({Key? key}) : super(key: key);

  @override
  _ArenaViewState createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  /* -------------------------------------------------------------------------- */
  /*                               STATE & FIELDS                               */
  /* -------------------------------------------------------------------------- */

  late GoogleMapController mapController;
  final loc.Location _location = loc.Location();

  final RxSet<Marker> markers = RxSet<Marker>();
  final RxSet<Polyline> _polylines = RxSet<Polyline>();
  final PolylinePoints _polylinePoints = PolylinePoints();

  // TODO: put your real key here
  static const _googleDirectionsKey = 'AIzaSyAIeaszJ60ZcjL9hNYpsQ_JD8w8J2vnmuQ';

  final TextEditingController _searchController = TextEditingController();

  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _customMarker2;

  static const LatLng _initialPosition = LatLng(37.7749, -122.4194);
  String _mapStyle = '';

  final CybercafesController _cybercafesController =
      Get.put(CybercafesController(remoteRepo: locator<RemoteRepoInterface>()));

  String? _selectedCafeId;
  bool _isMapControllerInitialized = false;
  LatLng? _userLatLng;
  Timer? debounce;

  /// `cafeId -> {distance: 'x km', duration: 'y mins'}`
  final Map<String, Map<String, String>> _distanceCache = {};

  final List<String> images = [
    'https://next-level.gg/assets/cafes/11.jpg',
    'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
    'https://media.assettype.com/afkgaming%2F2024-04%2Fe11d1515-bb0d-48a5-9ad9-1ddfdef286ef%2FUntitled_design_117_.png?auto=format%2Ccompress&dpr=1.0&w=1200',
    'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
    'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg'
  ];

  /* -------------------------------------------------------------------------- */
  /*                                INITIALISERS                                */
  /* -------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _cybercafesController.fetchCybercafes();
    });
    _loadMapStyle();
    _loadCustomMarker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cybercafesController.fetchCybercafes();
  }

  /* -------------------------------------------------------------------------- */
  /*                              HELPER FUNCTIONS                              */
  /* -------------------------------------------------------------------------- */

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
    setState(() {});
  }

  void _loadCustomMarker() async {
    _customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
      'assets/custom_marker.png',
    );
    _customMarker2 = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
      'assets/custom_marker2.png',
    );
  }

  LatLng _extractLatLng(Map<String, dynamic> cafe) {
    final locMap = cafe['address'] ?? cafe['location'] ?? {};
    final latRaw = locMap['latitude'] ?? 0;
    final lngRaw = locMap['longitude'] ?? 0;

    final double lat =
        latRaw is double ? latRaw : double.tryParse(latRaw.toString()) ?? 0.0;
    final double lng =
        lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString()) ?? 0.0;

    return LatLng(lat, lng);
  }

  void _updateCameraPosition(LatLng pos) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300),
        () => mapController.animateCamera(CameraUpdate.newLatLng(pos)));
  }

  /* -------------------------------------------------------------------------- */
  /*                       DISTANCE & ETA (Directions API)                      */
  /* -------------------------------------------------------------------------- */

  Future<Map<String, String>> _getDistanceDuration(
      LatLng dest, String cafeId) async {
    if (_userLatLng == null) {
      print('🛑 _userLatLng is null'); // <-- add
      return {'distance': '--', 'duration': '--'};
    }
    if (_userLatLng == null) return {'distance': '--', 'duration': '--'};
    if (_distanceCache.containsKey(cafeId)) return _distanceCache[cafeId]!;

    final url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_userLatLng!.latitude},${_userLatLng!.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving'
        '&key=$_googleDirectionsKey');
    print('➡️  Hitting URL: $url'); // <-- add
    final res = await http.get(url);
    print('⬅️  Status: ${res.statusCode}'); // <-- add
    print('⬅️  Body: ${res.body}'); // <-- add

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['routes'] != null &&
          data['routes'].isNotEmpty &&
          data['routes'][0]['legs'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        final dist = leg['distance']['text'] as String;
        final dur = leg['duration']['text'] as String;
        _distanceCache[cafeId] = {'distance': dist, 'duration': dur};
        return _distanceCache[cafeId]!;
      }
    }
    return {'distance': '--', 'duration': '--'};
  }

  /* -------------------------------------------------------------------------- */
  /*                           LOCATION & MARKER SETUP                          */
  /* -------------------------------------------------------------------------- */

  Future<void> _initializeLocation() async {
    if (!await _location.serviceEnabled() && !await _location.requestService())
      return;
    if (await _location.requestPermission() != loc.PermissionStatus.granted)
      return;

    final locData = await _location.getLocation();
    _userLatLng = LatLng(locData.latitude!, locData.longitude!);

    _updateCameraPosition(_userLatLng!);
    _addUserMarker(_userLatLng!);
    _fetchNearbyCybercafes();
  }

  void _addUserMarker(LatLng pos) {
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: pos,
        icon: _customMarker ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  Future<void> _fetchNearbyCybercafes() async {
    if (_cybercafesController.cybercafes.isEmpty) return;

    markers.addAll(_cybercafesController.cybercafes.map((cafe) {
      final LatLng pos = _extractLatLng(cafe);
      final isSelected = cafe['id'] == _selectedCafeId;

      return Marker(
        markerId: MarkerId(cafe['id'] ?? 'unknown'),
        position: pos,
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : (_customMarker2 ?? BitmapDescriptor.defaultMarker),
        infoWindow: InfoWindow(
          title: cafe['name'] ?? 'Unknown',
          snippet: isSelected ? 'Selected Location' : null,
        ),
      );
    }));
  }

  /* -------------------------------------------------------------------------- */
  /*                               ROUTE DRAWING                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _drawRoute(LatLng dest) async {
    if (_userLatLng == null) return;

    _polylines.clear();
    final result = await _polylinePoints.getRouteBetweenCoordinates(
      _googleDirectionsKey,
      PointLatLng(_userLatLng!.latitude, _userLatLng!.longitude),
      PointLatLng(dest.latitude, dest.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isEmpty) {
      Get.snackbar('Route', 'No route found.');
      return;
    }

    final id = PolylineId('route');
    _polylines.add(Polyline(
      polylineId: id,
      width: 6,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
      points:
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    ));

    // Optional: quick toast with ETA
    final info = await _getDistanceDuration(dest, 'route');
    Get.snackbar(
        'Route', 'Distance: ${info['distance']}  |  ETA: ${info['duration']}');

    setState(() {});
  }

  /* -------------------------------------------------------------------------- */
  /*                        EXTERNAL GOOGLE MAPS LAUNCHER                       */
  /* -------------------------------------------------------------------------- */

  Future<void> _openExternalMaps(LatLng dest) async {
    if (_userLatLng == null) return;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_userLatLng!.latitude},${_userLatLng!.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Cannot open Google Maps.');
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                             SEARCH BAR ACTION                              */
  /* -------------------------------------------------------------------------- */

  Future<void> _searchAndNavigate() async {
    if (_searchController.text.trim().isEmpty) return;
    try {
      final locs = await locationFromAddress(_searchController.text.trim());
      if (locs.isNotEmpty) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(
              LatLng(locs.first.latitude, locs.first.longitude)),
        );
      }
    } catch (_) {
      Get.snackbar('Error', 'Location not found.');
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                 UI PIECES                                 */
  /* -------------------------------------------------------------------------- */

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xffDE3A3A)),
        decoration: InputDecoration(
          labelText: 'Search for a location',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Color(0xffDE3A3A)),
            onPressed: _searchAndNavigate,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientCard(Map<String, dynamic> cafe, String image) {
    final LatLng cafeLatLng = _extractLatLng(cafe);

    Future<void> _jumpToCafe() async {
      if (!_isMapControllerInitialized) return;
      setState(() => _selectedCafeId = cafe['id']);
      markers.clear();
      await _fetchNearbyCybercafes();

      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: cafeLatLng, zoom: 16, tilt: 45),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        await _jumpToCafe();
        await Future.delayed(const Duration(milliseconds: 800));
        await Get.to(
          () => ArenaDetailView(
            images: image,
            title: cafe['cafe_name'] ?? 'Unknown Cafe',
            address: 'Owner: ${cafe['owner_name']}',
            openingHours: 'Created: ${cafe['created_at']}',
            availableGames: const ['Game 1', 'Game 2'],
            amenities: cafe['amenities'],
            contactInfo: 'Contact: contact@domain.com',
            reviews: const ['Great place!', 'Loved it!'],
            vendorId: cafe['vendor_id'],
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xff0E0E0E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                height: 250,
                width: 300,
                placeholder: (c, _) =>
                    const Center(child: RainbowGlowingLoader(size: 50)),
                errorWidget: (c, _, __) => Container(
                  height: 250,
                  width: 300,
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Text('Image Not Available',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0),
                          Colors.black.withOpacity(.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cafe['cafe_name'] ?? 'Unknown Cafe',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Mumbai | 9 - 12 am',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(Icons.circle,
                                  color: cafe['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 8),
                              const SizedBox(width: 4),
                              Text(
                                cafe['status'] == 'active' ? 'Open' : 'Close',
                                style: TextStyle(
                                    color: cafe['status'] == 'active'
                                        ? Colors.green
                                        : Colors.red),
                              ),
                              const SizedBox(width: 8),
                              // Distance · ETA
                              FutureBuilder<Map<String, String>>(
                                future: _getDistanceDuration(
                                    cafeLatLng, cafe['id'] ?? '0'),
                                builder: (context, snapshot) {
                                  final dist =
                                      snapshot.data?['distance'] ?? '--';
                                  final eta =
                                      snapshot.data?['duration'] ?? '--';
                                  return Text('$dist · $eta',
                                      style: const TextStyle(
                                          color: Colors.white70));
                                },
                              ),
                            ]),
                            Row(children: [
                              // Route icon
                              GestureDetector(
                                onTap: () async {
                                  await _jumpToCafe();
                                  await _drawRoute(cafeLatLng);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: const Color(0xffDE3A3A),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.route,
                                      color: Colors.black, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // External Maps icon
                              GestureDetector(
                                onTap: () => _openExternalMaps(cafeLatLng),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(12)),
                                  child:
                                      const Icon(Icons.map_outlined, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                  radius: 16,
                                  child: Icon(Icons.chevron_right, size: 20)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   BUILD                                    */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Obx(
              () => GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  mapController.setMapStyle(_mapStyle);
                  _isMapControllerInitialized = true;
                },
                initialCameraPosition:
                    const CameraPosition(target: _initialPosition, zoom: 16),
                markers: markers.toSet(),
                polylines: _polylines.toSet(),
                myLocationEnabled: true,
              ),
            ),
            Positioned(top: 50, left: 10, right: 10, child: _buildSearchBar()),
            Obx(() {
              if (_cybercafesController.isLoading.value) {
                return const Center(child: RainbowGlowingLoader(size: 50));
              }
              if (_cybercafesController.cybercafes.isEmpty) {
                return const Center(child: Text('No cybercafes available.'));
              }
              return Container(
                color: Colors.black,
                height: 300,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 249,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: _cybercafesController.cybercafes.length,
                        itemBuilder: (context, index) {
                          final cafe = _cybercafesController.cybercafes[index];
                          return _buildGradientCard(
                              cafe, images[index % images.length]);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                                text: 'Not found your favorite cafe, ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            TextSpan(
                                text: 'Let us know',
                                recognizer: TapGestureRecognizer()
                                  ..onTap =
                                      () => Get.to(() => const AddCafeScreen()),
                                style: const TextStyle(
                                    color: Color(0xffDE3A3A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const TextSpan(
                                text: ' about it',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
