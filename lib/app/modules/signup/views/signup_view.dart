
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../../routes/app_routes.dart';
import '../controllers/signup_controller.dart';

// ────────────────────────────────────────────────────────────────────────────────

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final SignUpController c = Get.put(SignUpController());
  final _formKey = GlobalKey<FormState>();
  static const _pad = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, String>?;

    if (args != null) {
      c.nameController.text = args['name'] ?? '';
      c.emailController.text = args['email'] ?? '';
      c.mobileNoController.text = args['phoneNumber'] ?? '';
    }

    // 🔹 Listener: whenever name changes → regenerate username
    c.nameController.addListener(() {
      final baseName = c.nameController.text.trim().isNotEmpty
          ? c.nameController.text.split(" ").first
          : "Player";

      final gamingWords = [
        "Ninja", "Warrior", "Shadow", "Hunter", "Sniper",
        "Dragon", "Knight", "Phantom", "Rogue", "Assassin",
        "Beast", "Predator", "Ghost", "Samurai", "Reaper"
      ];

      final random = Random();
      final word = gamingWords[random.nextInt(gamingWords.length)];
      final number = random.nextInt(900) + 100; // 100–999

      c.gameUserNameController.text = "$baseName$word$number";
    });

    // 🔹 Default gender = Male
    c.genderController.text = "Male";
  }


  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, String>?;
    final phoneFilled = (args?['phoneNumber']?.isNotEmpty ?? false);
    final emailFilled = (args?['email']?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: ()=>Get.back()),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      _field(c.nameController, 'Name',
                          autofill: AutofillHints.name),

                      // Game Username (auto-filled)
                      _userNameField(),



                      // Mobile
                      _mobileField(phoneFilled),

                      // Referral
                      _referralField(),

                      // Email
                      _field(c.emailController, 'Email',
                          readOnly: emailFilled, autofill: AutofillHints.email),
                      // Location button
                      // _locationBtn(),
                      //
                      // // Address
                      // _field(c.addressLine1Controller, 'Address Line 1',
                      //     autofill: AutofillHints.streetAddressLine1, required: false),
                      // _field(c.addressLine2Controller, 'Address Line 2',
                      //     autofill: AutofillHints.streetAddressLine2, required: false),

                      // const SizedBox(height: 20),
                      // _signupBtn(),
                      //
                      // TextButton(
                      //   onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
                      //   child: Text.rich(TextSpan(
                      //       text: 'Already have an account? ',
                      //       style: GoogleFonts.inter(color: Colors.white70),
                      //       children: [
                      //         TextSpan(
                      //           text: 'Login',
                      //           style: GoogleFonts.inter(
                      //               color: const Color(0xFF3AFF6B)),
                      //         )
                      //       ])),
                      // )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

      ),

      // 🔹 Bottom section
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _signupBtn(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: GoogleFonts.inter(color: Colors.white70),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: GoogleFonts.inter(color: const Color(0xFF3AFF6B)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── widgets ───────────────────────────────────────────

  Widget _field(TextEditingController ctl, String label,
      {String? autofill, bool readOnly = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctl,
        readOnly: readOnly,
        style: GoogleFonts.inter(
          color: readOnly ? Colors.grey.shade400 : Colors.white,
        ),
        autofillHints: autofill != null ? [autofill] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: readOnly ? Colors.grey.shade500 : Colors.white70,
          ),
          filled: readOnly, // fill only if readOnly
          fillColor: Colors.grey.shade900, // subtle grey bg
          contentPadding: _pad,
          enabledBorder: _border(readOnly ? Colors.grey.shade700 : const Color(0x3FFFFFFF)),
          focusedBorder: _border(readOnly ? Colors.grey.shade700 : const Color(0xFF3AFF6B)),
        ),
        validator: (v) {
          if (required && !readOnly && (v == null || v.trim().isEmpty)) {
            return 'Enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _mobileField(bool readOnly) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c.mobileNoController,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        maxLength: 10,
        enableInteractiveSelection: false, // disables paste
        textInputAction: TextInputAction.done,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          prefixText: '+91 ',
          prefixStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          counterText: '', // hides 0/10 counter
          contentPadding: _pad,
          enabledBorder: _border(const Color(0x3FFFFFFF)),
          focusedBorder: _border(const Color(0xFF3AFF6B)),
        ),
        inputFormatters: [
          // Only numbers and max 10 digits
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: (v) {
          if (!readOnly && (v == null || v.trim().isEmpty)) {
            return 'Enter Mobile Number';
          }
          if (!readOnly && v?.length != 10) {
            return 'Enter valid 10-digit number';
          }
          return null;
        },
      ),
    );
  }

  Widget _userNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c.gameUserNameController,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Game Username',
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          contentPadding: _pad,
          enabledBorder: _border(const Color(0x3FFFFFFF)),
          focusedBorder: _border(const Color(0xFF3AFF6B)),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter Game Username';
          return null;
        },
      ),
    );
  }





  Widget _genderDrop() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value:
            c.genderController.text.isNotEmpty ? c.genderController.text : null,
        dropdownColor: Colors.black,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          contentPadding: _pad,
          enabledBorder: _border(const Color(0x3FFFFFFF)),
          focusedBorder: _border(const Color(0xFF3AFF6B)),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (val) => c.genderController.text = val ?? '',
        validator: (val) => val == null || val.isEmpty ? 'Select gender' : null,
      ),
    );
  }

  // Widget _locationBtn() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         RGBLightFrame(width: Get.width, height: 50, borderRadius: 100),
  //         InkWell(
  //           onTap: c.fetchLocation,
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Icon(CupertinoIcons.location_solid, color: Colors.white),
  //               const SizedBox(width: 8),
  //               Text('Fetch Location',
  //                   style: GoogleFonts.inter(color: Colors.white)),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _signupBtn() {
    return Obx(() => Stack(
          children: [
            RGBLightFrame(width: Get.width, height: 50, borderRadius: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.isLoading.value
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          c.signUp();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: c.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: RainbowLoadingBar())
                    : Text(
                        'Sign Up',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
              ),
            )
          ],
        ));
  }
  Widget _referralField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c.referralCodeController,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Referral Code (Optional)',
          labelStyle: GoogleFonts.inter(color: Colors.white54), // lighter
          hintText: 'Enter if you have one',
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13,fontWeight: FontWeight.w100),
          contentPadding: _pad.copyWith(top: 10, bottom: 10), // smaller
          enabledBorder: _border(const Color(0x2FFFFFFF)),   // lighter border
          focusedBorder: _border(const Color(0xFF3AFF6B)),
        ),
        // 🔹 No validator → not mandatory
      ),
    );
  }

  // helper
  OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderSide: BorderSide(color: c),
      borderRadius: BorderRadius.circular(12));
}

