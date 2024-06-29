import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc; // Prefix the location package
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';

import 'arena_view_detailed.dart'; // Geocoding package

class ArenaView extends StatefulWidget {
  const ArenaView({super.key});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  late GoogleMapController mapController;
  final loc.Location _location = loc.Location();
  final Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController(); // Controller for the search bar
  BitmapDescriptor? _customMarker; // Custom marker for current location
  BitmapDescriptor? _customMarker2; // Custom marker for current location

  static const LatLng _initialPosition =
  LatLng(37.7749, -122.4194); // Default position (San Francisco)
  String _mapStyle = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadMapStyle();
    _loadCustomMarker(); // Load custom marker
  }

  void _loadCustomMarker() async {
    _customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48),devicePixelRatio: 2),
      'assets/custom_marker.png',
    );_customMarker2 = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48),devicePixelRatio: 2),
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
  }

  void _updateCurrentLocationMarker(loc.LocationData currentLocation) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: 'Your Location'),
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
          markerId: const MarkerId('current_location'),
          position: LatLng(latitude, longitude),
          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      _markers.addAll([
        Marker(
          markerId: const MarkerId('cafe_1'),
          position: LatLng(latitude + 0.01, longitude + 0.01),
          infoWindow: const InfoWindow(title: 'Gaming Cafe 1'),
          icon:_customMarker2?? BitmapDescriptor.defaultMarker,
        ),
        Marker(
          markerId: const MarkerId('cafe_332'),
          position: LatLng(latitude - 0.01, longitude - 0.01),
          infoWindow: const InfoWindow(title: 'Gaming Cafe 2'),
          icon:_customMarker2?? BitmapDescriptor.defaultMarker,

        ),
        Marker(
          markerId: const MarkerId('cafe_23'),
          position: LatLng(latitude - 0.013, longitude - 0.031),
          infoWindow: const InfoWindow(title: 'Gaming Cafe 2'),
          icon:_customMarker2?? BitmapDescriptor.defaultMarker,

        ),
        Marker(
          markerId: const MarkerId('cafe_32'),
          position: LatLng(latitude - 0.021, longitude - 0.031),
          infoWindow: const InfoWindow(title: 'Gaming Cafe 2'),
          icon:_customMarker2?? BitmapDescriptor.defaultMarker,

        ),
        Marker(
          markerId: const MarkerId('cafe_22'),
          position: LatLng(latitude - 0.301, longitude - 0.021),
          infoWindow: const InfoWindow(title: 'Gaming Cafe 2'),
          icon:_customMarker2?? BitmapDescriptor.defaultMarker,

        ),
      ]);
    });
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
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: false, // Disable the default blue marker
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
              initialChildSize: 0.2,
              minChildSize: 0.18,
              maxChildSize: 0.5,
              snap: true,
              builder: (BuildContext context, scrollController) {
                return Container(
                  height: 250,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    children: _markers
                        .where((marker) =>
                    marker.markerId.value != 'current_location')
                        .map((marker) => SizedBox(
                      width: 300,
                      height: 320,
                      child: gradientCardSample(marker),
                    ))
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget gradientCardSample(Marker marker) {
  return Container(
    height: 200,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: ShapeDecoration(
        color: Colors.grey[900],
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(36),
        )),
    child: ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    marker.infoWindow.title ?? 'Unknown Cafe',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "monospace",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 6),
                      SizedBox(width: 3),
                      Text('Open'),
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
                'Gaming Road, new ways - 6km ↱',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "monospace",
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Container(
          child: Image.network(
              'https://t3.ftcdn.net/jpg/04/29/97/24/360_F_429972422_idgQSEcP8Ur9ky1ZXXUlrGwx39wUjyqH.jpg'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              Get.to(ArenaDetailView(
                title: 'Epic Gaming Cafe',
                address: '123 Gamer St, Gametown, GT 56789',
                openingHours: 'Mon-Sun: 10 AM - 10 PM',
                availableGames: ['League of Legends', 'Overwatch', 'Minecraft', 'FIFA 21'],
                amenities: ['VR Experiences', 'Game Streaming', 'Food and Beverages'],
                contactInfo: '+123 456 7890 | contact@epicgamingcafe.com',
                reviews: [
                  'Amazing place! Loved the VR experience.',
                  'Great selection of games and very friendly staff.',
                  'The best place to hang out with friends and game!'
                ],
              ));              // Handle product button tap
            },
            style: ElevatedButton.styleFrom(
              primary: const Color.fromRGBO(58, 255, 107, 1.0),
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
}
