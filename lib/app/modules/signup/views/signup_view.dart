import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../../routes/app_routes.dart';
import '../controllers/signup_controller.dart';

class SignUpView extends StatefulWidget {
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final SignUpController controller = Get.put(SignUpController());
  final segmentService = locator<SegmentSdkService>();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    segmentService.onSignupStarted(referralCode: '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve Google Sign-In data from arguments
    final Map<String, String>? userData = Get.arguments as Map<String, String>?;

    final String phoneNumber = userData?['phoneNumber'] ?? '';

    // Prefill the controller's text fields with Google data if available
    if (userData != null) {
      if (userData['name'] != null && userData['name']!.isNotEmpty) {
        controller.nameController.text = userData['name']!;
      }
      if (userData['email'] != null && userData['email']!.isNotEmpty) {
        controller.emailController.text = userData['email']!;
      }
    }

    // Prefill the phone number in the controller
    if (phoneNumber.isNotEmpty) {
      controller.mobileNoController.text = phoneNumber;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: Get.width,
          height: Get.height,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'HASH.',
                  style: TextStyle(
                    color: Color(0xffDE3A3A),
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.76,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Name field
                      TextFormField(
                        controller: controller.nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 20),
                      // Game Username field
                      TextFormField(
                        controller: controller.gameUserNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Game Username',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your game username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Date of Birth field
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(
                                const Duration(days: 6570)), // 18 years ago
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xffDE3A3A),
                                    onPrimary: Colors.white,
                                    surface: Colors.black,
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            final months = [
                              'JAN',
                              'FEB',
                              'MAR',
                              'APR',
                              'MAY',
                              'JUN',
                              'JUL',
                              'AUG',
                              'SEP',
                              'OCT',
                              'NOV',
                              'DEC'
                            ];
                            final day = picked.day.toString().padLeft(2, '0');
                            final month = months[picked.month - 1];
                            final year = picked.year.toString();
                            final formattedDate = "$day-$month-$year";
                            controller.dobController.text = formattedDate;
                          }
                        },
                        child: TextFormField(
                          controller: controller.dobController,
                          style: const TextStyle(color: Colors.white),
                          readOnly:
                              true, // Make it read-only to show date picker
                          enabled:
                              false, // Disable the field to prevent keyboard
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            labelStyle: const TextStyle(color: Colors.white70),
                            suffixIcon: const Icon(Icons.calendar_today,
                                color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.white70),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your date of birth';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Gender field
                      DropdownButtonFormField<String>(
                        value: controller.genderController.text.isEmpty
                            ? null
                            : controller.genderController.text,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.black,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other',
                                  style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (value) {
                          controller.genderController.text = value ?? '';
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Email field (Prefilled with Google data)
                      TextFormField(
                        controller: controller.emailController,
                        style: const TextStyle(color: Colors.white),
                        readOnly: userData?['email'] != null &&
                            userData!['email']!
                                .isNotEmpty, // Disable editing if prefilled
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 20),
                      // Mobile Number field
                      TextFormField(
                        controller: controller.mobileNoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: phoneNumber.isNotEmpty
                              ? phoneNumber
                              : 'Mobile Number',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                      const SizedBox(height: 20),
                      // Referral Code field
                      TextFormField(
                        controller: controller.referralCodeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Referral Code (Optional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Fetch Location Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: Get.width,
                            height: 55,
                            child: RGBLightFrame(
                              width: Get.width,
                              height: Get.height,
                              borderRadius: 100,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              controller.fetchLocation();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.location_circle,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Fetch Location',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Other address fields
                      TextFormField(
                        controller: controller.addressLine1Controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Address Line 1',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        autofillHints: const [AutofillHints.streetAddressLine1],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: controller.addressLine2Controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Address Line 2',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        autofillHints: const [AutofillHints.streetAddressLine2],
                      ),
                      const SizedBox(height: 20),
                      // Submit button
                      Stack(
                        children: [
                          Container(
                            width: Get.width,
                            height: 50,
                            child: RGBLightFrame(
                              width: Get.width,
                              height: Get.height,
                              borderRadius: 10,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  controller.signUp();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Sign Up',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Get.offAllNamed(AppRoutes.LOGIN);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Login',
                              style: TextStyle(color: Color(0xFF3AFF6B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
