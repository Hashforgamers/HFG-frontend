import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      c.nameController.text        = args['name']        ?? '';
      c.emailController.text       = args['email']       ?? '';
      c.mobileNoController.text    = args['phoneNumber'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args        = Get.arguments as Map<String, String>?;
    final phoneFilled = (args?['phoneNumber']?.isNotEmpty ?? false);
    final emailFilled = (args?['email']?.isNotEmpty       ?? false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  onPressed: Get.back),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 12),
                      const Text('Sign Up',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),

                      const SizedBox(height: 20),
                      _field(c.nameController, 'Name',
                          autofill: AutofillHints.name),
                      _userNameField(),
                      _dobPicker(),
                      _genderDrop(),

                      _field(c.emailController, 'Email',
                          readOnly: emailFilled,
                          autofill: AutofillHints.email),
                      _field(c.mobileNoController, 'Mobile Number',
                          readOnly: phoneFilled,
                          autofill: AutofillHints.telephoneNumber),
                      _field(c.referralCodeController, 'Referral Code (Optional)', required: false),
                      _locationBtn(),

                      _field(c.addressLine1Controller, 'Address Line 1',
                          autofill: AutofillHints.streetAddressLine1, required: false),
                      _field(c.addressLine2Controller, 'Address Line 2',
                          autofill: AutofillHints.streetAddressLine2, required: false),


                      const SizedBox(height: 20),
                      _signupBtn(),

                      TextButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.LOGIN),
                        child: const Text.rich(TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                  text: 'Login',
                                  style: TextStyle(color: Color(0xFF3AFF6B)))
                            ])),
                      )
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

  // ───────────────────────── widgets ───────────────────────────────────────────

  Widget _field(TextEditingController ctl, String label,
      {String? autofill, bool readOnly = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctl,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.white),
        autofillHints: autofill != null ? [autofill] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          contentPadding: _pad,
          enabledBorder: _border(const Color(0x3FFFFFFF)),
          focusedBorder: _border(const Color(0xFF3AFF6B)),
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


  Widget _userNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Obx(() {
        return TextFormField(
          controller: c.gameUserNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Game Username',
            labelStyle: const TextStyle(color: Colors.white70),
            contentPadding: _pad,
            enabledBorder: _border(const Color(0x3FFFFFFF)),
            focusedBorder: _border(const Color(0xFF3AFF6B)),

          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter Game Username';
            Widget _userNameField() {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: c.gameUserNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Game Username',
                    labelStyle: const TextStyle(color: Colors.white70),
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
            return null;
          },
        );
      }),
    );
  }

  Widget _dobPicker() {
    return GestureDetector(
      onTap: _pickDob,
      child: AbsorbPointer(child: _field(c.dobController, 'Date of Birth')),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => _CupertinoDobPicker(initial: c.dobController.text),
    );
    if (picked != null) {
      final m = [
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
      c.dobController.text =
      '${picked.day.toString().padLeft(2, "0")}-${m[picked.month - 1]}-${picked.year}';
    }
  }

  Widget _genderDrop() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: c.genderController.text.isNotEmpty ? c.genderController.text : null,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: const TextStyle(color: Colors.white70),
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

  Widget _locationBtn() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RGBLightFrame(width: Get.width, height: 50, borderRadius: 100),
          InkWell(
            onTap: c.fetchLocation,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.location_solid, color: Colors.white),
                SizedBox(width: 8),
                Text('Fetch Location', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: c.isLoading.value
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign Up',
                style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    ));
  }

  // helper
  OutlineInputBorder _border(Color c) =>
      OutlineInputBorder(borderSide: BorderSide(color: c), borderRadius: BorderRadius.circular(12));
}

// ───────────────────────── Cupertino DOB picker widget ─────────────────────────
class _CupertinoDobPicker extends StatefulWidget {
  final String initial;
  const _CupertinoDobPicker({required this.initial});
  @override
  State<_CupertinoDobPicker> createState() => _CupertinoDobPickerState();
}

class _CupertinoDobPickerState extends State<_CupertinoDobPicker> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.tryParse(widget.initial) ?? DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: CupertinoDatePicker(
              backgroundColor: Colors.black,
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selected,
              maximumDate: DateTime.now(),
              onDateTimeChanged: (d) => _selected = d,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Done'),
          )
        ],
      ),
    );
  }
}
