import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/home/views/home_view.dart';
import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../../routes/app_routes.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Center(
          //   child: Container(
          //     width: Get.width*0.95,
          //     height: Get.height*0.6,
          //     child: RGBLightFrame(width: Get.width, height: Get.height,),
          //   ),
          // ),

          Center(
            child: Container(
              width: Get.width*0.85,
              height: Get.height*0.85,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                // color: Colors.grey[900]?.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    'HASH.',
                    style: TextStyle(
                      color:  Color.fromRGBO(58, 255, 107, 1.0),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.start,
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
                  TextField(
                    controller: controller.emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter Mobile Number',
                      prefix: Container(
                        child: Text('  +91   '),
                      ),

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
                  ),

                  SizedBox(height: 30),
                  Stack(
                    children: [
                      Container(
                        width: Get.width,
                        height: 50,
                        child: RGBLightFrame(width: Get.width, height: Get.height,borderRadius: 10,),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // controller.login();
                            Get.offAllNamed(AppRoutes.HOME);
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
              Obx(() {
                return Column(mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 55,),
                    Text(
                      controller.quote.value,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5,),

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
              })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
