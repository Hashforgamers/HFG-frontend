import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../data/models/user_model.dart';

/// Edit Profile in an Apple grouped-list style: avatar header, then inset
/// cards for gamer identity, personal details, contact and address, with a
/// Save capsule that only lights up once something has changed.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _green = Color(0xFF30D158);
  static const _card = Color(0xFF1C1C1E);
  static const _separator = Color(0x1FFFFFFF);
  static const _secondary = Color(0x99EBEBF5); // 60%
  static const _genders = ['Male', 'Female', 'Other'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final UserController userController = Get.put(UserController());
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _gameName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  String _gender = '';
  String _dob = '';

  User? _loadedFor;
  Map<String, String> _initial = const {};

  List<TextEditingController> get _controllers => [
    _name, _gameName, _email, _mobile, _address1, _address2, _state, _country,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadFrom(User user) {
    if (identical(_loadedFor, user)) return;
    _loadedFor = user;
    final e = user.contact?.electronicAddress;
    final p = user.contact?.physicalAddress;
    _name.text = user.name ?? '';
    _gameName.text = user.gameUserName ?? '';
    _email.text = e?.emailId ?? '';
    _mobile.text = e?.mobileNo ?? '';
    _address1.text = p?.addressLine1 ?? '';
    _address2.text = p?.addressLine2 ?? '';
    _state.text = p?.state ?? '';
    _country.text = p?.country ?? '';
    _gender = user.gender ?? '';
    _dob = user.dob ?? '';
    _initial = _snapshot();
  }

  Map<String, String> _snapshot() => {
    'name': _name.text.trim(),
    'gameUserName': _gameName.text.trim(),
    'email': _email.text.trim(),
    'mobile': _mobile.text.trim(),
    'address1': _address1.text.trim(),
    'address2': _address2.text.trim(),
    'state': _state.text.trim(),
    'country': _country.text.trim(),
    'gender': _gender,
    'dob': _dob,
  };

  List<String> get _changed {
    final now = _snapshot();
    return [
      for (final k in now.keys)
        if (now[k] != _initial[k]) k,
    ];
  }

  void _save(User user) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      Haptics.selection();
      return;
    }
    final changed = _changed;
    if (changed.isEmpty) return;
    Haptics.selection();

    user
      ..name = _name.text.trim()
      ..gameUserName = _gameName.text.trim()
      ..gender = _gender
      ..dob = _dob;
    final e = user.contact?.electronicAddress;
    e?.emailId = _email.text.trim();
    e?.mobileNo = _mobile.text.trim();
    final p = user.contact?.physicalAddress;
    p?.addressLine1 = _address1.text.trim();
    p?.addressLine2 = _address2.text.trim();
    p?.state = _state.text.trim();
    p?.country = _country.text.trim();

    segmentService.onProfileUpdated(updatedFields: changed);
    fbEventsService.onProfileUpdated(updatedFields: changed);
    // userController.updateUserData(user);
    setState(() => _initial = _snapshot());
  }

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 16 ? -0.35 : -0.1,
        height: 1.25,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _green,
        ),
        title: Text(
          'Edit Profile',
          style: _text(17, Colors.white, weight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: RainbowGlowingLoader(size: 50));
        }
        final user = userController.user.value;
        _loadFrom(user);
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      _header(user),
                      const SizedBox(height: 28),
                      _section('Gamer profile', [
                        _field(
                          controller: _name,
                          label: 'Name',
                          icon: Icons.person_rounded,
                          tint: const Color(0xFF0A84FF),
                          capitalization: TextCapitalization.words,
                          required: true,
                        ),
                        _field(
                          controller: _gameName,
                          label: 'Game username',
                          icon: Icons.sports_esports_rounded,
                          tint: _green,
                          required: true,
                          hint: 'Shown on leaderboards & lobbies',
                        ),
                      ]),
                      _section('Personal', [_genderRow(), _dobRow()]),
                      _section('Contact', [
                        _field(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.mail_rounded,
                          tint: const Color(0xFF5E5CE6),
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(s)
                                ? null
                                : 'Enter a valid email';
                          },
                        ),
                        _field(
                          controller: _mobile,
                          label: 'Mobile number',
                          icon: Icons.phone_rounded,
                          tint: _green,
                          keyboard: TextInputType.phone,
                          formatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                            LengthLimitingTextInputFormatter(13),
                          ],
                          validator: (v) {
                            final digits =
                                (v ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.isEmpty) return null;
                            return digits.length >= 10
                                ? null
                                : 'Enter a valid mobile number';
                          },
                        ),
                      ]),
                      _section('Address', [
                        _field(
                          controller: _address1,
                          label: 'Address line 1',
                          icon: Icons.home_rounded,
                          tint: const Color(0xFFFF9F0A),
                          capitalization: TextCapitalization.words,
                        ),
                        _field(
                          controller: _address2,
                          label: 'Address line 2',
                          icon: Icons.apartment_rounded,
                          tint: const Color(0xFFFF9F0A),
                          capitalization: TextCapitalization.words,
                        ),
                        _field(
                          controller: _state,
                          label: 'State',
                          icon: Icons.map_rounded,
                          tint: const Color(0xFFFF375F),
                          capitalization: TextCapitalization.words,
                        ),
                        _field(
                          controller: _country,
                          label: 'Country',
                          icon: Icons.public_rounded,
                          tint: const Color(0xFF64D2FF),
                          capitalization: TextCapitalization.words,
                          last: true,
                        ),
                      ]),
                    ],
                  ),
                ),
                _saveBar(user),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _header(User user) {
    final photoUrl = (user.photoUrl ?? '').trim().isNotEmpty
        ? (user.photoUrl ?? '').trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();
    final name = _name.text.trim();
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final gameName = _gameName.text.trim();

    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5CE07A), Color(0xFF1E9E3E)],
            ),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _initialsAvatar(initials),
                    )
                  : _initialsAvatar(initials),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name.isEmpty ? 'Your name' : name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _text(22, Colors.white, weight: FontWeight.w700),
        ),
        if (gameName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  color: _green.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              color: _green.withValues(alpha: 0.12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 14,
                  color: _green,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    gameName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(13, _green, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _initialsAvatar(String initials) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
      ),
    ),
    child: Center(
      child: initials.isEmpty
          ? const Icon(Icons.person_rounded, color: _secondary, size: 44)
          : Text(
              initials,
              style: _text(32, Colors.white, weight: FontWeight.w700),
            ),
    ),
  );

  // ─── Grouped section card ────────────────────────────────────────────────

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 7),
            child: Text(
              title.toUpperCase(),
              style: _text(12.5, _secondary, weight: FontWeight.w600)
                  .copyWith(letterSpacing: 0.4),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(36)),
                side: BorderSide(color: Color(0x5900DC00), width: 0.8),
              ),
              color: _card,
            ),
            child: Column(
              children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 58,
                      color: _separator,
                    ),
                  row,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconTile(IconData icon, Color tint) => Container(
    width: 30,
    height: 30,
    decoration: ShapeDecoration(
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      color: tint,
    ),
    child: Icon(icon, color: Colors.white, size: 17),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color tint,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool required = false,
    bool last = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _iconTile(icon, tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _text(12, _secondary)),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboard,
                  textCapitalization: capitalization,
                  inputFormatters: formatters,
                  textInputAction:
                      last ? TextInputAction.done : TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  cursorColor: _green,
                  style: _text(16, Colors.white, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                    border: InputBorder.none,
                    hintText: hint ?? 'Add ${label.toLowerCase()}',
                    hintStyle: _text(16, const Color(0x4DEBEBF5)),
                    errorStyle: _text(12, const Color(0xFFFF453A)),
                  ),
                  validator: (v) {
                    if (required && (v == null || v.trim().isEmpty)) {
                      return '$label is required';
                    }
                    return validator?.call(v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRow() {
    final current = _genders.firstWhere(
      (g) => g.toLowerCase() == _gender.trim().toLowerCase(),
      orElse: () => '',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _iconTile(Icons.wc_rounded, const Color(0xFFBF5AF2)),
          const SizedBox(width: 14),
          Text('Gender', style: _text(16, Colors.white, weight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: current.isEmpty ? null : current,
              backgroundColor: const Color(0xFF2C2C2E),
              thumbColor: const Color(0xFF636366),
              padding: const EdgeInsets.all(2),
              onValueChanged: (v) {
                if (v == null) return;
                Haptics.selection();
                setState(() => _gender = v);
              },
              children: {
                for (final g in _genders)
                  g: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      g,
                      style: _text(13, Colors.white, weight: FontWeight.w600),
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime? get _dobDate => DateTime.tryParse(_dob.trim());

  String get _dobLabel {
    final d = _dobDate;
    if (d != null) return '${d.day} ${_months[d.month - 1]} ${d.year}';
    return _dob.trim();
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dobDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _green,
            onPrimary: Colors.black,
            surface: _card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    setState(() => _dob = '${picked.year}-$mm-$dd');
  }

  Widget _dobRow() {
    final label = _dobLabel;
    return InkWell(
      onTap: _pickDob,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            _iconTile(Icons.cake_rounded, const Color(0xFFFF375F)),
            const SizedBox(width: 14),
            Text(
              'Date of birth',
              style: _text(16, Colors.white, weight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              label.isEmpty ? 'Select' : label,
              style: _text(15, label.isEmpty ? _secondary : _green),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _secondary),
          ],
        ),
      ),
    );
  }

  // ─── Save bar ────────────────────────────────────────────────────────────

  Widget _saveBar(User user) {
    final dirty = _changed.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: _separator, width: 0.5)),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: dirty ? 1 : 0.4,
        child: GestureDetector(
          onTap: dirty ? () => _save(user) : null,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5CE07A), _green, Color(0xFF1E9E3E)],
                stops: [0, 0.5, 1],
              ),
              shadows: dirty
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.4),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              dirty ? 'Save changes' : 'No changes',
              style: _text(16, Colors.black, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
