import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

import '../../../utils/widgets/glow_neon_loader.dart';
import '../../data/models/user_model.dart';

class ProfileView extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final _formKey = GlobalKey<FormState>();
  final segmentService = locator<SegmentSdkService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(CupertinoIcons.back, color: Color(0xffDE3A3A)),
        ),
      ),
      body: Obx(() {
        if (userController.isLoading.value) {
          return Center(
            child: RainbowGlowingLoader(size: 50),
          );
        }

        final user = userController.user.value;
        return Padding(
          padding: const EdgeInsets.all(10.0),
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
                  onChanged: (value) => user.name = value,
                ),
                _buildTextField(
                  initialValue: user.gameUserName!,
                  labelText: 'Game Username',
                  onChanged: (value) => user.gameUserName = value,
                ),
                _buildTextField(
                  initialValue: user.gender!,
                  labelText: 'Gender',
                  onChanged: (value) => user.gender = value,
                ),
                _buildTextField(
                  initialValue: user.dob ?? '',
                  labelText: 'Date of Birth',
                  onChanged: (value) => user.dob = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.electronicAddress?.emailId ?? '',
                  labelText: 'Email',
                  onChanged: (value) =>
                      user.contact?.electronicAddress?.emailId = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.electronicAddress?.mobileNo ?? '',
                  labelText: 'Mobile Number',
                  onChanged: (value) =>
                      user.contact?.electronicAddress?.mobileNo = value,
                ),
                _buildTextField(
                  initialValue:
                      user.contact?.physicalAddress?.addressLine1 ?? '',
                  labelText: 'Address Line 1',
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.addressLine1 = value,
                ),
                _buildTextField(
                  initialValue:
                      user.contact?.physicalAddress?.addressLine2 ?? '',
                  labelText: 'Address Line 2',
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.addressLine2 = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.physicalAddress?.state ?? '',
                  labelText: 'State',
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.state = value,
                ),
                _buildTextField(
                  initialValue: user.contact?.physicalAddress?.country ?? '',
                  labelText: 'Country',
                  onChanged: (value) =>
                      user.contact?.physicalAddress?.country = value,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      segmentService.onProfileUpdated(
                        updatedFields: [
                          'name',
                        ],
                      );
                      // userController.updateUserData(user);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xffDE3A3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Update',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
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
              : AssetImage('assets/default_profile.png')
                  as ImageProvider, // Fallback to a local asset if no photoUrl
        ),
        const SizedBox(height: 20),
        Text(
          user.name!,
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          user.contact?.electronicAddress?.emailId ?? '',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String labelText,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: TextStyle(color: Colors.white),
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
