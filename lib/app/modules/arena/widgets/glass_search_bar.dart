import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlassSearchBar extends StatefulWidget {
  const GlassSearchBar({super.key});

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  final TextEditingController _searchCtl = TextEditingController();

  Future<void> _searchAndGo() async {
    final query = _searchCtl.text.trim();
    if (query.isEmpty) return;
    try {
      final res = await locationFromAddress(query);
      if (res.isNotEmpty) {
        final latLng = LatLng(res[0].latitude, res[0].longitude);
        // Notify listeners with coordinates
        // You can use an event bus or controller if needed
        print('Navigate to: $latLng');
      }
    } catch (_) {
      Get.snackbar('Error', 'Location not found');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: const Color(0xff338125).withOpacity(.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xff338125)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  style: GoogleFonts.inter(color: Colors.white),
                  cursorColor: const Color(0xff338125),
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    hintStyle: GoogleFonts.inter(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _searchAndGo(),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xff338125),
                ),
                onPressed: _searchAndGo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
