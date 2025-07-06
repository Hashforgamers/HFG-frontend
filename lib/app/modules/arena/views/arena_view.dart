// ignore_for_file: avoid_print

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
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  /* ────────────────────────────────────────────────────────────────────────── */
  /*  STATE                                                                    */
  /* ────────────────────────────────────────────────────────────────────────── */

  final CybercafesController _cafeCtr =
  Get.put(CybercafesController(remoteRepo: locator<RemoteRepoInterface>()));

  late GoogleMapController _mapCtr;
  final loc.Location _loc = loc.Location();

  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final _polylinePoints = PolylinePoints();

  final TextEditingController _searchCtl = TextEditingController();
  Timer? _camDebounce;

  LatLng? _userLatLng;
  String? _selectedCafeId;
  String _mapStyle = '';

  /// Directions API response cache  (cafeId  ->  distance / duration)
  final Map<String, Map<String, String>> _distanceCache = {};

  /// ⚠️  Replace with build-time env variable or secure storage
  static const _gmapsKey = 'AIzaSyAIeaszJ60ZcjL9hNYpsQ_JD8w8J2vnmuQ';
  bool _mapReady = false;              // NEW
  bool _playedZoom = false;            // NEW

  BitmapDescriptor? _markerUser, _markerCafe, _markerCafeHighlighted;

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
    _mapStyle = await rootBundle.loadString('assets/map_style.json');

    _markerUser = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/custom_marker.png',
    );

    _markerCafe = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/custom_marker2.png',
    );

    _markerCafeHighlighted =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  LOCATION INIT                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _initLocation() async {
    if (!await _loc.serviceEnabled()) {
      if (!await _loc.requestService()) return;
    }
    if (await _loc.requestPermission() != loc.PermissionStatus.granted) return;

    final locData = await _loc.getLocation();
    _userLatLng = LatLng(locData.latitude!, locData.longitude!);
    _tryPlayZoom();                    // attempt GTA zoom once coords ready
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  CAMERA & MOVEMENT                                                        */
  /* ────────────────────────────────────────────────────────────────────────── */

  void _smoothMoveCamera(LatLng target, {double zoom = 15}) {
    _camDebounce?.cancel();
    _camDebounce = Timer(const Duration(milliseconds: 280), () {
      _mapCtr.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom)));
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
  /*  SEARCH                                                                   */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _searchAndGo() async {
    final query = _searchCtl.text.trim();
    if (query.isEmpty) return;
    try {
      final res = await locationFromAddress(query);
      if (res.isNotEmpty) {
        _smoothMoveCamera(LatLng(res[0].latitude, res[0].longitude));
      }
    } catch (_) {
      Get.snackbar('Error', 'Location not found');
    }
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  MARKERS                                                                  */
  /* ────────────────────────────────────────────────────────────────────────── */

  LatLng _latLngFromCafe(Map<String, dynamic> cafe) {
    final locData = cafe['address'] ?? cafe['location'] ?? {};
    final lat = double.tryParse('${locData['latitude']}') ?? 0.0;
    final lng = double.tryParse('${locData['longitude']}') ?? 0.0;
    return LatLng(lat, lng);
  }

  void _addUserMarker() {
    if (_userLatLng == null) return;
    markers.add(Marker(
      markerId: const MarkerId('me'),
      position: _userLatLng!,
      icon: _markerUser ?? BitmapDescriptor.defaultMarker,
    ));
  }

  void _refreshCafeMarkers() {
    markers.removeWhere((m) => m.markerId.value.startsWith('cafe_'));

    for (final cafe in _cafeCtr.cybercafes) {
      final id = '${cafe['id'] ?? cafe.hashCode}';
      final pos = _latLngFromCafe(cafe);
      markers.add(Marker(
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
      ));
    }
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  DISTANCE + DURATION (Directions API)                                     */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<Map<String, String>> _distanceInfo(LatLng dest, String id) async {
    if (_userLatLng == null) return {'distance': '--', 'duration': '--'};
    if (_distanceCache.containsKey(id)) return _distanceCache[id]!;
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=${_userLatLng!.latitude},${_userLatLng!.longitude}'
            '&destination=${dest.latitude},${dest.longitude}'
            '&mode=driving'
            '&key=$_gmapsKey');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if ((data['routes'] as List).isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        _distanceCache[id] = {
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
        };
      }
    }
    return _distanceCache[id]!;
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  ROUTE DRAWING                                                            */
  /* ────────────────────────────────────────────────────────────────────────── */

  Future<void> _drawRoute(LatLng dest) async {
    if (_userLatLng == null) return;
    final result = await _polylinePoints.getRouteBetweenCoordinates(
      _gmapsKey,
      PointLatLng(_userLatLng!.latitude, _userLatLng!.longitude),
      PointLatLng(dest.latitude, dest.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isEmpty) {
      Get.snackbar('Route', 'No route found');
      return;
    }
    polylines.clear();
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      color: const Color(0xff338125),
      width: 6,
      points: result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(),
    ));
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
            '&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open Google Maps');
    }
  }

  /* ────────────────────────────────────────────────────────────────────────── */
  /*  UI HELPERS                                                               */
  /* ────────────────────────────────────────────────────────────────────────── */

  Widget _glassSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.15),
            borderRadius: BorderRadius.circular(25),
            border:
            Border.all(color: const Color(0xff338125).withOpacity(.2)),
          ),
          child: Row(children: [
            const Icon(Icons.search, color: Color(0xff338125)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtl,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xff338125),
                decoration: const InputDecoration(
                  hintText: 'Search location',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _searchAndGo(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Color(0xff338125)),
              onPressed: _searchAndGo,
            )
          ]),
        ),
      ),
    );
  }

  Widget _locateMeBtn() {
    return Positioned(
      bottom: 280,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'locateMe',
        mini: true,
        backgroundColor: const Color(0xff338125),
        child: const Icon(Icons.my_location, color: Colors.black),
        onPressed:
        _userLatLng == null ? null : () => _smoothMoveCamera(_userLatLng!),
      ),
    );
  }

  Widget _cafeCarousel() {
    // if (_cafeCtr.isLoading.value) {
    //   return const Center(child: RainbowGlowingLoader(size: 50));
    // }
    if (_cafeCtr.cybercafes.isEmpty) {
      return const Center(child: Text('No cybercafes available'));
    }

    _refreshCafeMarkers();

    const dummyImgs = [
      'https://next-level.gg/assets/cafes/11.jpg',
      'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
      'https://media.assettype.com/afkgaming/2024-04/e11d1515-bb0d-48a5-9ad9-1ddfdef286ef/Untitled_design_117_.png',
      'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
      'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg',
    ];

    return SizedBox(
      height: 230,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 8,top: 10),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _cafeCtr.cybercafes.length,
        itemBuilder: (_, i) {
          final cafe = _cafeCtr.cybercafes[i];
          return _gradientCard(
            cafe: cafe,
            img: dummyImgs[i % dummyImgs.length],
          );
        },
      ),
    );
  }

  Widget _gradientCard({
    required Map<String, dynamic> cafe,
    required String img,
  }) {
    final pos = _latLngFromCafe(cafe);
    final id = '${cafe['id'] ?? cafe.hashCode}';

    return GestureDetector(
      onTap: () async {
        _selectedCafeId = id;
        _smoothMoveCamera(pos, zoom: 16);
        _refreshCafeMarkers();
        await Future.delayed(const Duration(milliseconds: 600));
        await Get.to(() => ArenaDetailView(
          images: img,
          title: cafe['cafe_name'] ?? 'Unknown Cafe',
          address: 'Owner: ${cafe['owner_name']}',
          openingHours: 'Created: ${cafe['created_at']}',
          availableGames: cafe['available_games'] ?? ['N/A'],
          amenities: cafe['amenities'] ?? [],
          contactInfo: 'contact@domain.com',
          reviews: cafe['reviews'] ?? ['Great place!'],
          vendorId: cafe['vendor_id'] ?? 0,
        ));
      },
      child: Container(
        width: 300,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xff0E0E0E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: img,
              width: 300,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
              const Center(child: RainbowGlowingLoader(size: 40)),
              errorWidget: (_, __, ___) =>
              const Center(child: Icon(Icons.error, color: Colors.white)),
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
                  child: _cardFooter(cafe, pos, id),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _cardFooter(Map<String, dynamic> cafe, LatLng pos, String id) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cafe['cafe_name'] ?? 'Unknown',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.circle,
                  color: cafe['status'] == 'active' ? Colors.green : Colors.red,
                  size: 8),
              const SizedBox(width: 4),
              Text(
                cafe['status'] == 'active' ? 'Open' : 'Closed',
                style: TextStyle(
                    color: cafe['status'] == 'active' ? Colors.green : Colors.red),
              ),
              const SizedBox(width: 8),
              FutureBuilder<Map<String, String>>(
                future: _distanceInfo(pos, id),
                builder: (_, snap) {
                  final dist = snap.data?['distance'] ?? '--';
                  final dur = snap.data?['duration'] ?? '--';
                  return Text('$dist · $dur',
                      style: const TextStyle(color: Colors.white70));
                },
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _drawRoute(pos),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: const Color(0xff338125),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.route, size: 18, color: Colors.black),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openExternalMaps(pos),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: const Color(0xff338125),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.map, size: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GoogleMap(
                initialCameraPosition:
                const CameraPosition(target: LatLng(20, 77), zoom: 4),
                myLocationEnabled: true,
                markers: markers.toSet(),
                polylines: polylines.toSet(),
                onMapCreated: (ctrl) {
                  _mapCtr = ctrl;
                  _mapCtr.setMapStyle(_mapStyle);
                  _mapReady = true;
                  _tryPlayZoom();
                },
                zoomControlsEnabled: false,
              ),
              Positioned(top: 16, left: 16, right: 16, child: _glassSearchBar()),
              _locateMeBtn(),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.only(bottom: 8),
                child: _cafeCarousel(),
              ),
            ],
          );
        }),
      ),
    );
  }
}
