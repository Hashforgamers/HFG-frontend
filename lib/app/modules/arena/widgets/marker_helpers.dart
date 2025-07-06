import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show Size, VoidCallback, rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Loads the custom Google Map style from a JSON asset.
Future<String> loadMapStyle() async {
  try {
    return await rootBundle.loadString('assets/map_style.json');
  } catch (e) {
    return ''; // fallback to default style if asset not found
  }
}

/// Loads a custom bitmap icon from assets.
Future<BitmapDescriptor> loadCustomMarker(String assetPath, {double size = 48}) async {
  return await BitmapDescriptor.fromAssetImage(
    ImageConfiguration(size: Size(size, size)),
    assetPath,
  );
}

/// Creates a user marker
Marker createUserMarker(LatLng position, BitmapDescriptor icon) {
  return Marker(
    markerId: const MarkerId('me'),
    position: position,
    icon: icon,
    infoWindow: const InfoWindow(title: 'You are here'),
  );
}

/// Creates a café marker with a tap callback
Marker createCafeMarker({
  required String id,
  required LatLng position,
  required String title,
  required BitmapDescriptor icon,
  required VoidCallback onTap,
}) {
  return Marker(
    markerId: MarkerId('cafe_$id'),
    position: position,
    icon: icon,
    infoWindow: InfoWindow(title: title),
    onTap: onTap,
  );
}
