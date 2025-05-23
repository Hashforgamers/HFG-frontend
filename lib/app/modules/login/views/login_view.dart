import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../../routes/app_routes.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: Get.width ,
              height: Get.height * 0.85,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                     Center(
                      child: Image.asset('assets/Transparent Logo.png',scale: 8,)
                      // child: Text(
                      //   'HASH.',
                      //   style: TextStyle(
                      //     color: Color(0xffDE3A3A),
                      //     fontSize: 44,
                      //     fontWeight: FontWeight.w900,
                      //   ),
                      // ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.phoneNumberController,
                      style: const TextStyle(color: Colors.white,letterSpacing: 4),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefix: Text('  +91  '),
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
                          return 'Please enter your phone number';
                        } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
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
                                controller.isLoading.value = true; // Start loader immediately

                                controller.signInWithPhoneNumber();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Continue', style: TextStyle(color: Colors.white,                                  fontSize: 16,
                            )),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,height: 50,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.white70, // Adjust text color
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,height: 50,
                          ),
                        ),
                      ],
                    ),

                                   GestureDetector(
                      onTap: controller.googleSignIn,
                      child: Stack(alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: Get.width,
                            height: 55,
                            child: RGBLightFrame(
                              width: Get.width,
                              height: Get.height,
                              borderRadius:25,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://cdn-icons-png.flaticon.com/512/2702/2702602.png', // Ensure the Google logo is saved in assets
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  color: Colors.white, // Google branding black text
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // TextButton(
                    //   onPressed: () {
                    //     Get.offAllNamed(AppRoutes.SIGNUP);
                    //   },
                    //   child: const Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Text('New to Hash? ', style: TextStyle(color: Colors.white70)),
                    //       Text(' Signup', style: TextStyle(color: Color(0xFF3AFF6B))),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xffDE3A3A)),
                  ),
                ),
              );
            } else {
              return SizedBox.shrink(); // Empty widget when not loading
            }
          }),
        ],
      ),
    );
  }
}
