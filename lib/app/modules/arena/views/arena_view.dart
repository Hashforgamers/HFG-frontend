import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
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
  final RxSet<Marker> markers = RxSet<Marker>();
  TextEditingController _searchController = TextEditingController();
  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _customMarker2;
  static const LatLng _initialPosition = LatLng(37.7749, -122.4194);
  String _mapStyle = '';
  final CybercafesController _cybercafesController = Get.put(CybercafesController());

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
      ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
      'assets/custom_marker.png',
    );
    _customMarker2 = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48), devicePixelRatio: 2),
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
    _updateCameraPosition(LatLng(locationData.latitude!, locationData.longitude!));


    _addMarkers(locationData.latitude!, locationData.longitude!);
    _fetchNearbyCybercafes(locationData.latitude!, locationData.longitude!);
  }

  void _addMarkers(double latitude, double longitude) {
    markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(latitude, longitude),
        icon: _customMarker ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
    );
  }


  Future<void> _fetchNearbyCybercafes(double latitude, double longitude) async {
    try {
      if (_cybercafesController.cybercafes.isEmpty) return;

      markers.addAll(
        _cybercafesController.cybercafes.map((cafe) {
          return Marker(
            markerId: MarkerId(cafe['id'] ?? 'unknown'),
            position: LatLng(
              cafe['location']['latitude'] ?? 0.0,
              cafe['location']['longitude'] ?? 0.0,
            ),
            icon: _customMarker2 ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: cafe['name'] ?? 'Unknown'),
          );
        }),
      );
    } catch (e) {
      print('Fetch Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          Get.to(PastBookingsScreen());
        },
        child: Container(
          width: 108,
          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color:Color(0xffDE3A3A)


          ),

          child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2,color: Colors.black,size: 15,),
              Text('Bookings',style: TextStyle(color: Colors.black,fontSize: 15,fontWeight: FontWeight.bold),),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(alignment: Alignment.bottomCenter,
          children: [
            Obx(() => GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                mapController.setMapStyle(_mapStyle);
              },
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: markers.toSet(), // Convert RxSet to Set for GoogleMap
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
                return Center(child: RainbowGlowingLoader(size: 50),);
              }

              if (_cybercafesController.cybercafes.isEmpty) {
                return Center(child: Text('No cybercafes available.'));
              }

              return RepaintBoundary(
                child: Container(color: Colors.black,height: 250,alignment: Alignment.bottomCenter,
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
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
      padding: EdgeInsets.symmetric(horizontal: 15),
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
            icon: Icon(Icons.search, color: Color(0xffDE3A3A)),
            onPressed: _searchAndNavigate,
          ),
        ),
        style: TextStyle(color: Color(0xffDE3A3A)),
      ),
    );
  }
  Widget _buildGradientCard(Map<String, dynamic> cafe, String image) {
    return GestureDetector(
      onTap: () async{
        await Get.to(ArenaDetailView(
          images: image,
          title: cafe['cafe_name'] ?? 'Unknown Cafe',
          address: 'Owner: ${cafe['owner_name']}',
          openingHours: 'Created: ${cafe['created_at']}', // Example data
          availableGames: ['Game 1', 'Game 2'], // Placeholder
          amenities: ['Amenity 1', 'Amenity 2'], // Placeholder
          contactInfo: 'Contact: contact@domain.com', // Placeholder
          reviews: ['Great place!', 'Loved it!'],
          vendorId:cafe['vendor_id']// Placeholder
        ));
      },
      child: Container(width: 300,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xff0E0E0E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  height: 320,
                  width: 400,
                  placeholder: (context, url) => Center(child: RainbowGlowingLoader(size: 50),),
                  errorWidget: (context, url, error) => Container(
                    height: 320,
                    width: 400,
                    color: Colors.grey,
                    child: Center(
                      child: Text(
                        'Image Not Available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )


            ),
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ListTile(
                  title: Text(cafe['cafe_name'] ?? 'Unknown Cafe', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Mumbai | 9 - 12am', style: TextStyle(color: Colors.white70)),
                  trailing: Container(width: 100,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.circle,color: cafe['status'] == 'active' ? Colors.green : Colors.red,size: 8,),
                                SizedBox(width: 3,),
                                Text(cafe['status']== 'active' ?'Open':'Close', style: TextStyle(color: cafe['status'] == 'active' ? Colors.green : Colors.red)),
                              ],
                            ),
                            SizedBox(height: 5,),
                            Text('2.3KM', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        SizedBox(width: 10,),
                        CircleAvatar(radius: 20,
                          child: Icon(Icons.chevron_right),
                        )
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
