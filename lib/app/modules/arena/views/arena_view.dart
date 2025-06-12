import 'dart:async';
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

import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'arena_view_detailed.dart';
import 'add_cafe_screen.dart';

class ArenaView extends StatefulWidget {
  const ArenaView({Key? key}) : super(key: key);

  @override
  _ArenaViewState createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  late GoogleMapController mapController;
  final loc.Location _location = loc.Location();
  final RxSet<Marker> markers = RxSet<Marker>();
  final TextEditingController _searchController = TextEditingController();
  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _customMarker2;
  static const LatLng _initialPosition = LatLng(37.7749, -122.4194);
  String _mapStyle = '';
  final CybercafesController _cybercafesController =
      Get.put(CybercafesController(
    remoteRepo: locator<RemoteRepoInterface>(),
  ));
  String? _selectedCafeId;
  bool _isMapControllerInitialized = false;

  List<String> images = [
    'https://next-level.gg/assets/cafes/11.jpg',
    'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
    'https://media.assettype.com/afkgaming%2F2024-04%2Fe11d1515-bb0d-48a5-9ad9-1ddfdef286ef%2FUntitled_design_117_.png?auto=format%2Ccompress&dpr=1.0&w=1200',
    'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
    'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg'
  ];
  Timer? debounce;

  void _updateCameraPosition(LatLng position) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      mapController.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

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

  Future<void> _loadMapStyle() async {
    String style = await rootBundle.loadString('assets/map_style.json');
    setState(() {
      _mapStyle = style;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch cybercafes again when coming back to this page
    _cybercafesController.fetchCybercafes();
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

  void _initializeLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    final permissionGranted = await _location.requestPermission();
    if (permissionGranted != loc.PermissionStatus.granted) return;

    final locationData = await _location.getLocation();
    _updateCameraPosition(
        LatLng(locationData.latitude!, locationData.longitude!));

    _addMarkers(locationData.latitude!, locationData.longitude!);
    _fetchNearbyCybercafes(locationData.latitude!, locationData.longitude!);
  }

  void _addMarkers(double latitude, double longitude) {
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(latitude, longitude),
        icon: _customMarker ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  Future<void> _fetchNearbyCybercafes(double latitude, double longitude) async {
    try {
      if (_cybercafesController.cybercafes.isEmpty) return;

      markers.addAll(
        _cybercafesController.cybercafes.map((cafe) {
          final bool isSelected = cafe['id'] == _selectedCafeId;
          return Marker(
            markerId: MarkerId(cafe['id'] ?? 'unknown'),
            position: LatLng(
              cafe['location']['latitude'] ?? 0.0,
              cafe['location']['longitude'] ?? 0.0,
            ),
            icon: isSelected
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : (_customMarker2 ?? BitmapDescriptor.defaultMarker),
            infoWindow: InfoWindow(
              title: cafe['name'] ?? 'Unknown',
              snippet: isSelected ? 'Selected Location' : null,
            ),
          );
        }),
      );
    } catch (e) {
      debugPrint('Fetch Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: GestureDetector(
      //   onTap: () {
      //     Get.to(PastBookingsScreen());
      //   },
      //   child: Container(
      //     width: 108,
      //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //     decoration: BoxDecoration(
      //         borderRadius: BorderRadius.circular(22),
      //         color: const Color(0xffDE3A3A)),
      //     child: const Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //       crossAxisAlignment: CrossAxisAlignment.center,
      //       children: [
      //         Icon(
      //           Icons.qr_code_2,
      //           color: Colors.black,
      //           size: 15,
      //         ),
      //         Text(
      //           'Bookings',
      //           style: TextStyle(
      //               color: Colors.black,
      //               fontSize: 15,
      //               fontWeight: FontWeight.bold),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Obx(() => GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    mapController.setMapStyle(_mapStyle);
                    _isMapControllerInitialized = true;
                  },
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 16,
                  ),
                  markers:
                      markers.toSet(), // Convert RxSet to Set for GoogleMap
                  myLocationEnabled: true,
                )),
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: _buildSearchBar(),
            ),
            Obx(() {
              if (_cybercafesController.isLoading.value) {
                return const Center(
                  child: RainbowGlowingLoader(size: 50),
                );
              }

              if (_cybercafesController.cybercafes.isEmpty) {
                return const Center(child: Text('No cybercafes available.'));
              }

              return RepaintBoundary(
                child: Container(
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
                              cafe,
                              images[index % images.length],
                            );
                          },
                        ),
                      ),
                      Container(
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(() => const AddCafeScreen());
                                  },
                                text: 'Let us know',
                                style: const TextStyle(
                                  color: Color(0xffDE3A3A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: ' about it',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search for a location',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Color(0xffDE3A3A)),
            onPressed: _searchAndNavigate,
          ),
        ),
        style: const TextStyle(color: Color(0xffDE3A3A)),
      ),
    );
  }

  Widget _buildGradientCard(Map<String, dynamic> cafe, String image) {
    return GestureDetector(
      onTap: () async {
        // Animate camera to the selected cafe's location
        if (cafe['location'] != null && _isMapControllerInitialized) {
          final LatLng cafeLocation = LatLng(
            cafe['location']['latitude'] ?? 0.0,
            cafe['location']['longitude'] ?? 0.0,
          );

          // Update selected cafe ID and refresh markers
          setState(() {
            _selectedCafeId = cafe['id'];
          });

          // Force refresh markers
          markers.clear();
          await _fetchNearbyCybercafes(
            cafe['location']['latitude'] ?? 0.0,
            cafe['location']['longitude'] ?? 0.0,
          );

          // Animate camera with zoom and bearing
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: cafeLocation,
                zoom: 16.0,
                bearing: 0,
                tilt: 45.0,
              ),
            ),
          );

          // Add a slight delay before navigating to detail view
          await Future.delayed(const Duration(milliseconds: 800));
        }

        await Get.to(() => ArenaDetailView(
            images: image,
            title: cafe['cafe_name'] ?? 'Unknown Cafe',
            address: 'Owner: ${cafe['owner_name']}',
            openingHours: 'Created: ${cafe['created_at']}',
            availableGames: const ['Game 1', 'Game 2'],
            amenities: const ['Amenity 1', 'Amenity 2'],
            contactInfo: 'Contact: contact@domain.com',
            reviews: const ['Great place!', 'Loved it!'],
            vendorId: cafe['vendor_id']));
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
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                height: 250,
                width: 300,
                placeholder: (context, url) => const Center(
                  child: RainbowGlowingLoader(size: 50),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  width: 300,
                  color: Colors.grey,
                  child: const Center(
                    child: Text(
                      'Image Not Available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
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
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cafe['cafe_name'] ?? 'Unknown Cafe',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mumbai | 9 - 12am',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: cafe['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 8,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cafe['status'] == 'active' ? 'Open' : 'Close',
                                  style: TextStyle(
                                    color: cafe['status'] == 'active'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '2.3KM',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (cafe['location'] != null &&
                                        _isMapControllerInitialized) {
                                      try {
                                        final LatLng cafeLocation = LatLng(
                                          cafe['location']['latitude'] ?? 0.0,
                                          cafe['location']['longitude'] ?? 0.0,
                                        );

                                        setState(() {
                                          _selectedCafeId = cafe['id'];
                                        });

                                        markers.clear();
                                        await _fetchNearbyCybercafes(
                                          cafe['location']['latitude'] ?? 0.0,
                                          cafe['location']['longitude'] ?? 0.0,
                                        );

                                        await mapController.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: cafeLocation,
                                              zoom: 16.0,
                                              bearing: 0,
                                              tilt: 45.0,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint('Navigation Error: $e');
                                        Get.snackbar(
                                          'Error',
                                          'Failed to navigate to location',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                      }
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Location data not available',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffDE3A3A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.navigation,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                  radius: 16,
                                  child: Icon(Icons.chevron_right, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndNavigate() async {
    String query = _searchController.text;
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final location = locations.first;
          mapController.animateCamera(CameraUpdate.newLatLng(
            LatLng(location.latitude, location.longitude),
          ));
        }
      } catch (e) {
        Get.snackbar('Error', 'Location not found.');
      }
    }
  }
}
