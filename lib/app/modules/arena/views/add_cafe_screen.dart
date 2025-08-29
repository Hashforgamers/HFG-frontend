import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/firebase_service.dart';

import '../../../../utils/widgets/loader.dart';

class AddCafeScreen extends StatefulWidget {
  const AddCafeScreen({super.key});

  @override
  State<AddCafeScreen> createState() => _AddCafeScreenState();
}

class _AddCafeScreenState extends State<AddCafeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromPincode() async {
    if (_pincodeController.text.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First, get location from pincode
      List<Location> locations =
          await locationFromAddress(_pincodeController.text);
      if (locations.isNotEmpty) {
        Location location = locations.first;

        // Then, get address details from coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address = [
            if (place.street?.isNotEmpty ?? false) place.street,
            if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
            if (place.locality?.isNotEmpty ?? false) place.locality,
            if (place.administrativeArea?.isNotEmpty ?? false)
              place.administrativeArea,
            if (place.postalCode?.isNotEmpty ?? false) place.postalCode,
            if (place.country?.isNotEmpty ?? false) place.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');

          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not fetch address details. Please enter manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitCafeRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _firebaseService.addCafeRequest(
          cafeName: _nameController.text.trim(),
          pincode: _pincodeController.text.trim(),
          address: _addressController.text.trim(),
        );

        if (success) {
          Get.back(); // First pop the screen
          Get.snackbar(
            'Success',
            'Your cafe request has been submitted successfully! We will review it shortly.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Add New Cafe',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cafe Details',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Cafe Name',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDE3A3A)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cafe name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pincodeController,
                    style: GoogleFonts.inter(color: Colors.white),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (value) {
                      if (value.length == 6) {
                        _getAddressFromPincode();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Cafe Pincode',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      counterStyle: GoogleFonts.inter(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDE3A3A)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pincode';
                      }
                      if (value.length != 6) {
                        return 'Pincode must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      TextFormField(
                        controller: _addressController,
                        style: GoogleFonts.inter(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Cafe Address',
                          labelStyle: GoogleFonts.inter(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xffDE3A3A)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter cafe address';
                          }
                          return null;
                        },
                      ),
                      if (_isLoading)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: RainbowLoadingBar(

                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitCafeRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffDE3A3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: RainbowLoadingBar(

                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: RainbowLoadingBar()
              ),
            ),
        ],
      ),
    );
  }
}
