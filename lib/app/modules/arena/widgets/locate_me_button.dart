import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocateMeButton extends StatelessWidget {
  final LatLng? Function() userLatLngGetter;
  final VoidCallback moveCamera;

  const LocateMeButton({
    super.key,
    required this.userLatLngGetter,
    required this.moveCamera,
  });

  @override
  Widget build(BuildContext context) {
    final userLatLng = userLatLngGetter();
    return Positioned(
      bottom: 280,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'locateMe',
        mini: true,
        backgroundColor: const Color(0xff00DC00),
        onPressed: userLatLng == null ? null : moveCamera,
        child: const Icon(Icons.my_location, color: Colors.black),
      ),
    );
  }
}
