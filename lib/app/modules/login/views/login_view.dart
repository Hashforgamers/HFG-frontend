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
              width: Get.width * 0.85,
              height: Get.height * 0.85,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Form(
                key: _formKey,
                child: ListView(    physics: BouncingScrollPhysics(),

                  shrinkWrap: true,
                  children: [
                    Center(
                      child: Text(
                        'HASH.',
                        style: TextStyle(
                          color: Color(0xff00D701),
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: controller.emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
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
                                controller.login();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Continue', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 20),
                    Obx(() {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(height: 55),
                          Text(
                            controller.quote.value,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5),
                          Text(
                            '~${controller.character.value}',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }),
                    SizedBox(height: 45),
                    TextButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.SIGNUP);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to Hash? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            ' Signup',
                            style: TextStyle(color: Color(0xFF3AFF6B)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 45),
                    TextButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.HOME);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Are you a Dev? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            ' Proceed',
                            style: TextStyle(color: Color(0xFF3AFF6B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
