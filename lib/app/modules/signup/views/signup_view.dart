import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';            // ← ADDED
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

  // ← ADDED: access auth + provider helpers
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool get _cameFromOAuth {
    final u = _auth.currentUser;
    if (u == null) return false;
    return u.providerData.any(
          (p) => p.providerId == 'apple.com' || p.providerId == 'google.com',
    );
  }

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, String>?;
    final firebaseName = _auth.currentUser?.displayName ?? '';

    // Only prefill from args for *non*-OAuth flows (manual/phone).
    if (args != null && !_cameFromOAuth) {
      c.nameController.text = args['name'] ?? '';
      c.emailController.text = args['email'] ?? '';
      c.mobileNoController.text = args['phoneNumber'] ?? '';
    } else if (_cameFromOAuth) {
      c.mobileNoController.text = args?['phoneNumber'] ?? '';
      final firebaseName  = _auth.currentUser?.displayName ?? '';
      final firebaseEmail = _auth.currentUser?.email ?? '';
      c.nameController.text  = firebaseName;     // ← add
      c.emailController.text = firebaseEmail;    // ← add
    }

    // 🧠 Generate game username ONCE using cleaned-up name
    final rawName = !_cameFromOAuth
        ? c.nameController.text
        : firebaseName;

    if (rawName.trim().isNotEmpty) {
      final base = rawName.replaceAll(RegExp(r'\s+'), ''); // Remove all spaces
      final gamerTag = _generateGamerUsername(base);
      c.gameUserNameController.text = gamerTag;
    }

    // 🔹 Default gender = Male
    c.genderController.text = "Male";

    // 🔁 Regenerate gamer username if nameController changes (manual login only)
    if (!_cameFromOAuth) {
      c.nameController.addListener(() {
        final baseName = c.nameController.text.trim().replaceAll(' ', '');
        if (baseName.isNotEmpty) {
          c.gameUserNameController.text = _generateGamerUsername(baseName);
        }
      });
    }
  }
  String _generateGamerUsername(String base) {
    final gamingWords = [
      "Ninja", "Warrior", "Sniper", "Slayer", "Assassin",
      "Crusher", "Striker", "Hunter", "Brawler", "Fighter",
      "Executioner", "Killer", "Battler", "Bruiser", "Sharpshot",
      "Bomber", "Mauler", "Breaker", "Rager", "Bludgeon","Dragon", "Phoenix", "Wraith", "Demon", "Shadow",
      "Specter", "Reaper", "Grim", "Phantom", "Ghost",
      "Shinigami", "Banshee", "Ghoul", "Raven", "Valkyrie",
      "Soulstealer", "Apparition", "Haunt", "Necro", "Poltergeist","Commando", "Rogue", "Merc", "Agent", "Soldier",
      "Operator", "Captain", "Sergeant", "Sniper", "Pilot",
      "Marksman", "Corporal", "Brigadier", "Sapper", "Trooper","Drifter", "Runner", "Dash", "Rush", "Blaze",
      "Flash", "Zoom", "Velocity", "Rapid", "Zephyr",
      "Surge", "Jet", "Boost", "Quickshot", "Dashblade","Venom", "Viper", "Fury", "Toxin", "Dagger",
      "Rage", "Blood", "Inferno", "Scythe", "Claw",
      "Darklord", "Hellfire", "Ember", "Doom", "Rupture",
      "Slash", "Hex", "Oblivion", "Decay", "Ravage","Cyber", "Glitch", "Matrix", "Pixel", "Neo",
      "Byte", "Bot", "AI", "Quantum", "Cortex",
      "Override", "Sync", "Binary", "Circuit", "Echo",
      "CodeX", "Virus", "Firewall", "Protocol", "Omega","Frost", "Blaze", "Storm", "Thunder", "Flame",
      "Ice", "Ember", "Ash", "Quake", "Bolt",
      "Typhoon", "Tempest", "Vortex", "Avalanche", "Gale",
      "Hurricane", "Dust", "Fireball", "Hail", "Ignite"
    ];
    final random = Random();
    final word = gamingWords[random.nextInt(gamingWords.length)];
    final number = random.nextInt(900) + 100; // 100–999

    return "$base$word$number";
  }


  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, String>?;
    final phoneFilled = (args?['phoneNumber']?.isNotEmpty ?? false);

    // ← ADDED: identity from Firebase for info labels (not inputs)
    final firebaseName  = _auth.currentUser?.displayName ?? '';
    final firebaseEmail = _auth.currentUser?.email ?? '';

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

                      // Name (only for non-OAuth)
                      if (!_cameFromOAuth)
                        _field(c.nameController, 'Name',
                            autofill: AutofillHints.name)
                      else
                        _infoRow('Name', firebaseName.isEmpty ? '—' : firebaseName),

                      // Game Username (auto-filled)
                      _userNameField(),

                      // Mobile
                      _mobileField(phoneFilled),

                      // Referral
                      _referralField(),

                      // Email (only for non-OAuth). For OAuth, show read-only label.
                      if (!_cameFromOAuth)
                        _field(c.emailController, 'Email',
                            autofill: AutofillHints.email)
                      else
                        _infoRow('Email', firebaseEmail.isEmpty ? '—' : firebaseEmail),

                      // If you later re-enable address/location, keep them optional only.
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
                      style: GoogleFonts.inter(color: const Color(0xff00DC00)),
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

  Widget _infoRow(String label, String value) {                 // ← ADDED
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: _pad,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x3FFFFFFF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(color: Colors.white70)),
            ),
            Flexible(
              child: Text(
                value.isEmpty ? '—' : value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          filled: readOnly,
          fillColor: Colors.grey.shade900,
          contentPadding: _pad,
          enabledBorder: _border(readOnly ? Colors.grey.shade700 : const Color(0x3FFFFFFF)),
          focusedBorder: _border(readOnly ? Colors.grey.shade700 : const Color(0xff00DC00)),
        ),
        validator: (v) {
          // Validators will not run for OAuth because the fields are not rendered.
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
        maxLength: 15, // Max length for international numbers (E.164)
        // inputFormatters: [
        //   FilteringTextInputFormatter.digitsOnly, // ✅ allows only numbers
        // ],
        enableInteractiveSelection: false, // ✅ disables copy/paste/select
        // keyboardType: TextInputType.number,
        // maxLength: 10,
        // enableInteractiveSelection: false, // disables paste
        textInputAction: TextInputAction.done,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          counterText: "", // hides character counter
          labelText: 'Mobile Number',
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          // prefixText: '+ ', // ✅ just '+' for any country code
          // prefixStyle: GoogleFonts.inter(
          //   color: Colors.white,
          //   fontWeight: FontWeight.w500,
          // ),
          prefixText: '+91 ',
          prefixStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          // counterText: '', // hides 0/10 counter
          contentPadding: _pad,
          enabledBorder: _border(const Color(0x3FFFFFFF)),
          focusedBorder: _border(const Color(0xff00DC00)),
        ),
        inputFormatters: [
          // Only numbers and max 10 digits
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: (v) {
          if (!readOnly && (v == null || v
              .trim()
              .isEmpty)) {
            return 'Enter Mobile Number';
          }
          if (!readOnly && v!.length < 7) {
            return 'Enter valid number';
            if (!readOnly && v?.length != 10) {
              return 'Enter valid 10-digit number';
            }
            return null;
          }
        })
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
          focusedBorder: _border(const Color(0xff00DC00)),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter Game Username';
          return null;
        },
      ),
    );
  }

  // Widget _genderDrop() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: DropdownButtonFormField<String>(
  //       value:
  //       c.genderController.text.isNotEmpty ? c.genderController.text : null,
  //       dropdownColor: Colors.black,
  //       style: GoogleFonts.inter(color: Colors.white),
  //       decoration: InputDecoration(
  //         labelText: 'Gender',
  //         labelStyle: GoogleFonts.inter(color: Colors.white70),
  //         contentPadding: _pad,
  //         enabledBorder: _border(const Color(0x3FFFFFFF)),
  //         focusedBorder: _border(const Color(0xff00DC00)),
  //       ),
  //       items: const [
  //         DropdownMenuItem(value: 'Male', child: Text('Male')),
  //         DropdownMenuItem(value: 'Female', child: Text('Female')),
  //         DropdownMenuItem(value: 'Other', child: Text('Other')),
  //       ],
  //       onChanged: (val) => c.genderController.text = val ?? '',
  //       validator: (val) => val == null || val.isEmpty ? 'Select gender' : null,
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
          labelStyle: GoogleFonts.inter(color: Colors.white54),
          hintText: 'Enter if you have one',
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13, fontWeight: FontWeight.w100),
          contentPadding: _pad.copyWith(top: 10, bottom: 10),
          enabledBorder: _border(const Color(0x2FFFFFFF)),
          focusedBorder: _border(const Color(0xff00DC00)),
        ),
      ),
    );
  }

  // helper
  OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderSide: BorderSide(color: c),
      borderRadius: BorderRadius.circular(12));
}
