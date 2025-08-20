import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../data/models/user_model.dart';

class ProfileView extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final _formKey = GlobalKey<FormState>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back, color: Color(0xff00D701)),
        ),
      ),
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: RainbowGlowingLoader(size: 50));
        }

        final user = userController.user.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(user),
                const SizedBox(height: 30),
                _buildTextField(
                  initialValue: user.name!,
                  labelText: 'Name',
                  icon: Icons.person,
                  onChanged: (value) => user.name = value,
                ),
                _buildTextField(
                  initialValue: user.gameUserName!,
                  labelText: 'Game Username',
                  icon: Icons.games,
                  onChanged: (value) => user.gameUserName = value,
                ),
                _buildTextField(
                  initialValue: user.gender!,
                  labelText: 'Gender',
                  icon: Icons.person_outline,
                  onChanged: (value) => user.gender = value,
                ),
                _buildTextField(
                  initialValue: user.dob ?? '',
                  labelText: 'Date of Birth',
                  icon: Icons.calendar_today,
                  onChanged: (value) => user.dob = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.electronicAddress?.emailId ?? '',
                  labelText: 'Email',
                  icon: Icons.email,
                  onChanged: (value) =>
                      user.contact?.electronicAddress?.emailId = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.electronicAddress?.mobileNo ?? '',
                  labelText: 'Mobile Number',
                  icon: Icons.phone,
                  onChanged: (value) =>
                      user.contact?.electronicAddress?.mobileNo = value,
                ),
                _buildTextField(
                  initialValue:
                      user.contact?.physicalAddress?.addressLine1 ?? '',
                  labelText: 'Address Line 1',
                  icon: Icons.location_on,
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.addressLine1 = value,
                ),
                _buildTextField(
                  initialValue:
                      user.contact?.physicalAddress?.addressLine2 ?? '',
                  labelText: 'Address Line 2',
                  icon: Icons.location_city,
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.addressLine2 = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.physicalAddress?.state ?? '',
                  labelText: 'State',
                  icon: Icons.map,
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.state = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.physicalAddress?.country ?? '',
                  labelText: 'Country',
                  icon: Icons.public,
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.country = value,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      segmentService.onProfileUpdated(updatedFields: ['name']);
                      fbEventsService.onProfileUpdated(updatedFields: ['name']);
                      // userController.updateUserData(user);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00D701),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!)
              : const AssetImage('assets/default_profile.png')
                    as ImageProvider, // Fallback to a local asset if no photoUrl
        ),
        const SizedBox(height: 20),
        Text(
          user.name!,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          user.contact?.electronicAddress?.emailId ?? '',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String labelText,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xff00D701)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white70),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xff00D701)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: GoogleFonts.inter(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }
}
