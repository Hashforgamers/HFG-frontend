import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../utils/service.dart';
import '../controllers/cafe_controller.dart';
import 'arena_view_detailed.dart';

class ArenaView extends StatefulWidget {
  const ArenaView({Key? key}) : super(key: key);

  @override
  _ArenaViewState createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  late GoogleMapController mapController;
  final loc.Location _location = loc.Location();
  final Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController();
  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _customMarker2;
  static const LatLng _initialPosition = LatLng(
      37.7749, -122.4194); // Default position (San Francisco)
  String _mapStyle = '';
  final CybercafesController _cybercafesController = Get.put(CybercafesController());
  final BookingController _bookingController = Get.put(BookingController());
  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadMapStyle();
    _loadCustomMarker();
  }

  void _loadCustomMarker() async {
    _customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
      'assets/custom_marker.png',
    );
    _customMarker2 = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
      'assets/custom_marker2.png',
    );
  }

  void _initializeLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    final locationData = await _location.getLocation();
    mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(locationData.latitude!, locationData.longitude!)));

    // Add markers
    _addMarkers(locationData.latitude!, locationData.longitude!);

    // Listen for location changes and update the marker
    _location.onLocationChanged.listen((loc.LocationData currentLocation) {
      _updateCurrentLocationMarker(currentLocation);
    });

    // Fetch nearby cybercafes initially
    _fetchNearbyCybercafes(locationData.latitude!, locationData.longitude!);
  }

  void _updateCurrentLocationMarker(loc.LocationData currentLocation) {
    setState(() {
      _markers.removeWhere((marker) =>
      marker.markerId.value == 'current_location');
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(
              currentLocation.latitude!, currentLocation.longitude!),
          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
    });
    mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(currentLocation.latitude!, currentLocation.longitude!)));
  }

  void _addMarkers(double latitude, double longitude) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(latitude, longitude),
          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  Future<void> _fetchNearbyCybercafes(double latitude, double longitude) async {
    final authToken = await _getToken();

    // try {
      await _cybercafesController.setUserLocation(latitude, longitude);
      await _cybercafesController.fetchNearbyCybercafes(latitude, longitude);

      // Clear existing markers and add fetched cybercafes as markers
      setState(() {
        _markers.removeWhere((marker) =>
        marker.markerId.value != 'current_location');
        _cybercafesController.cybercafes.forEach((cafe) {
          _markers.add(
            Marker(
              markerId: MarkerId(cafe['_id']),
              position: LatLng(
                  cafe['location']['latitude'], cafe['location']['longitude']),
              icon: _customMarker2 ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(title: cafe['name']),
            ),
          );
        });
      });
    // } catch (e) {
    //   print('Error fetching nearby cybercafes: $e');
    // }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadMapStyle() async {
    String style = await rootBundle.loadString('assets/map_style.json');
    setState(() {
      _mapStyle = style;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
  }

  Future<void> _searchAndNavigate() async {
    String query = _searchController.text;
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final location = locations.first;
          mapController.animateCamera(CameraUpdate.newLatLng(
              LatLng(location.latitude, location.longitude)));
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(query),
                position: LatLng(location.latitude, location.longitude),
                infoWindow: InfoWindow(title: query),
              ),
            );
          });
        } else {
          Get.snackbar('Location Not Found', 'Please enter a valid location.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to find the location.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: true,
            ),
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchAndNavigate,
                    ),
                  ],
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.7,
              snap: true,
              builder: (BuildContext context, scrollController) {
                return Container(
                  height: 250,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),
                  child: ListView.builder(
                    itemCount: _cybercafesController.cybercafes.length,
                    itemBuilder: (context, index) {
                      final cafe = _cybercafesController.cybercafes[index];
                      return SizedBox(
                        width: 300,
                        height: 320,
                        child: gradientCardSample(cafe),
                      );
                    },
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,

                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget gradientCardSample(Map<String, dynamic> cafe) {
    bool isActive = cafe['address']['is_active'];
    int distance = cafe['distance']=='Infinity'?0:cafe['distance'];

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: ShapeDecoration(
        color: Color(0xff1E1E1E),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cafe['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "monospace",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: Color(0xff39FF14), size: 12,),
                    SizedBox(width: 3),
                    Text(isActive ? 'Open' : 'Closed'),
                    SizedBox(width: 3),
                    Text('(24hrs)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
            child: Text(
              '${cafe['address']['addressLine1']} - ${metersToKilometers(distance).toStringAsFixed(2)} km ↱',
              style: TextStyle(
                color: Colors.white,
                fontFamily: "monospace",
                fontSize: 15,
              ),
            ),
          ),
          Container(
            height: 130,width: Get.width, // Adjust the height as needed
            child: Image.network(
              'https://t3.ftcdn.net/jpg/04/29/97/24/360_F_429972422_idgQSEcP8Ur9ky1ZXXUlrGwx39wUjyqH.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle button tap (navigate to details or any other action)
                Get.to(ArenaDetailView(
                  title: cafe['name'],
                  address: '${cafe['address']['addressLine1']}, ${cafe['address']['State']}, ${cafe['address']['Country']} - ${cafe['address']['pincode']}',
                  openingHours: 'Mon-Sun: 10 AM - 10 PM', // Example data, replace with actual data
                  availableGames: [
                    'League of Legends',
                    'Overwatch',
                    'Minecraft',
                    'FIFA 21'
                  ], // Example data, replace with actual data
                  amenities: [
                    'VR Experiences',
                    'Game Streaming',
                    'Food and Beverages'
                  ], // Example data, replace with actual data
                  contactInfo: '+123 456 7890 | contact@${cafe['name'].toLowerCase().replaceAll(' ', '')}.com', // Example data, replace with actual data
                  reviews: [
                    'Amazing place! Loved the VR experience.',
                    'Great selection of games and very friendly staff.',
                    'The best place to hang out with friends and game!'
                  ], // Example data, replace with actual data
                ));
              },
              style: ElevatedButton.styleFrom(
                primary: const Color(0xff00D701),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                minimumSize: Size(double.infinity, 30),
              ),
              child: const Text(
                'View',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }}