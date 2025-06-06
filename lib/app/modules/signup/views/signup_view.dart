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

    final nameController = TextEditingController(
      text: userData?['name'], // Prefill name if available
    );
    final emailController = TextEditingController(
      text: userData?['email'], // Prefill email if available
    );
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
              Container(
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
                        controller: nameController,
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
                      // Email field (Prefilled with Google data)
                      TextFormField(
                        controller: emailController.text.isEmpty?controller.emailController:emailController,
                        style: const TextStyle(color: Colors.white),
                        readOnly: emailController.text.isEmpty?false:true, // Disable editing
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
