import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/about/about_page.dart';
import 'package:hash/app/modules/community/models/host_verification.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
import 'package:hash/app/modules/need_help/need_help_page.dart';
import 'package:hash/app/modules/profile/profile_view.dart';
import 'package:hash/app/modules/refferal/views/referral_view_with_controller.dart';
import 'package:hash/app/modules/social/friend_service.dart';
import 'package:hash/app/modules/social/friends_view.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/widgets/glow_neon_loader.dart';
import '../../data/models/user_model.dart' as model;
import '../../data/services/user_controller.dart';
import '../../routes/app_routes.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  UserController userController = Get.put(UserController());
  final segmentService = locator<SegmentSdkService>();
  final FriendService _friendService = FriendService();
  late Future<HostVerification?> _hostVerification;
  int _profileTab = 0;

  @override
  void initState() {
    super.initState();
    _hostVerification = CommunityApi().getMyHostVerification();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        userController.user.value.contact?.electronicAddress?.emailId ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: _green,
              )
            : null,
        title: Obx(
          () => Text(
            _profileHandle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(17, Colors.white, weight: FontWeight.w600),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share profile',
            onPressed: _shareProfile,
            icon: const Icon(CupertinoIcons.paperplane, size: 22),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettingsSheet(email),
            icon: const Icon(CupertinoIcons.line_horizontal_3, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xff00DC00),
        backgroundColor: const Color(0xFF171717),
        onRefresh: () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) await userController.fetchUserData(uid);
          if (mounted) {
            setState(() {
              _hostVerification = CommunityApi().getMyHostVerification();
            });
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 8),
            _buildProfileHeader(userController),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _profileAction(
                      label: 'Edit profile',
                      icon: CupertinoIcons.pencil,
                      primary: true,
                      onTap: () => Get.to(() => const ProfileView()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileAction(
                      label: 'Share profile',
                      icon: CupertinoIcons.share,
                      onTap: _shareProfile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _squareAction(
                    icon: CupertinoIcons.person_add,
                    tooltip: 'Find players',
                    onTap: () => Get.to(() => const FriendsView(initialTab: 2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildGamePassport(),
            const SizedBox(height: 22),
            _buildProfileTabs(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_profileTab),
                  child: _buildProfileTabContent(email),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _green = Color(0xFF30D158);
  static const _card = Color(0xFF1C1C1E);
  static const _hint = Color(0x5900DC00);
  static const _secondary = Color(0x99EBEBF5); // 60%
  static const _fill = Color(0x3D767680);

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 16 ? -0.35 : -0.1,
        height: 1.25,
      );

  ShapeDecoration _appleCard({
    double radius = 40,
    Color color = _card,
    Color border = _hint,
    Gradient? gradient,
  }) => ShapeDecoration(
    shape: ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      side: BorderSide(color: border, width: 0.8),
    ),
    color: gradient == null ? color : null,
    gradient: gradient,
  );

  Widget _iconTile(IconData icon, Color tint, {double size = 34}) => Container(
    width: size,
    height: size,
    decoration: ShapeDecoration(
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(size * 0.6)),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(tint, Colors.white, 0.18)!, tint],
      ),
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.55),
  );

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserController userController) {
    return Obx(() {
      if (userController.isLoading.value) {
        return const Center(child: RainbowGlowingLoader(size: 50));
      }

      final user = userController.user.value;
      final photoUrl = (user.photoUrl?.trim().isNotEmpty ?? false)
          ? user.photoUrl!.trim()
          : (FirebaseAuth.instance.currentUser?.photoURL ?? '').trim();
      final hasPhoto = photoUrl.isNotEmpty;
      final name = (user.name ?? '').trim();
      final displayName = name.isEmpty ? 'Hash Player' : name;
      final initials = name
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
      final referrals = user.referralCount ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
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
                        blurRadius: 22,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF2C2C2E),
                      backgroundImage: hasPhoto
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: hasPhoto
                          ? null
                          : initials.isEmpty
                          ? const Icon(
                              CupertinoIcons.person_fill,
                              color: _secondary,
                              size: 34,
                            )
                          : Text(
                              initials,
                              style: _text(
                                28,
                                Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<List<FriendRelationship>>(
                    stream: _friendService.watchRelationships(),
                    builder: (context, snapshot) {
                      final relationships = snapshot.data ?? const [];
                      final friends = relationships
                          .where((item) => item.status == 'accepted')
                          .length;
                      final requests = relationships
                          .where(
                            (item) => item.isIncoming(
                              _friendService.currentUid ?? '',
                            ),
                          )
                          .length;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: _appleCard(radius: 36),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _profileStat(
                                '$friends',
                                'Friends',
                                () => Get.to(
                                  () => const FriendsView(initialTab: 0),
                                ),
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 0.5,
                                indent: 6,
                                endIndent: 6,
                                color: Color(0x1FFFFFFF),
                              ),
                              _profileStat(
                                '$requests',
                                'Requests',
                                () => Get.to(
                                  () => const FriendsView(initialTab: 1),
                                ),
                                highlight: requests > 0,
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 0.5,
                                indent: 6,
                                endIndent: 6,
                                color: Color(0x1FFFFFFF),
                              ),
                              _profileStat('$referrals', 'Referrals', () {
                                final email =
                                    user.contact?.electronicAddress?.emailId ??
                                    '';
                                segmentService.onReferralViewed(email: email);
                                Get.to(
                                  () =>
                                      ReferralViewWithController(email: email),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(20, Colors.white, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                FutureBuilder<HostVerification?>(
                  future: _hostVerification,
                  builder: (context, snapshot) {
                    final isRegisteredHost =
                        snapshot.data?.status ==
                        HostVerificationStatus.verified;
                    if (!isRegisteredHost) return const SizedBox.shrink();
                    return const Tooltip(
                      message: 'Verified HASH host',
                      child: Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0A84FF),
                        size: 19,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Play. Compete. Connect. 🎮', style: _text(14, _secondary)),
          ],
        ),
      );
    });
  }

  Widget _profileStat(
    String value,
    String label,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: _text(
                  20,
                  highlight ? _green : Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(label, style: _text(11.5, _secondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final fg = primary ? _green : Colors.white;
    return Material(
      color: primary ? _green.withValues(alpha: 0.14) : _fill,
      shape: StadiumBorder(
        side: BorderSide(
          color: primary ? _green.withValues(alpha: 0.45) : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(14, fg, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _squareAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: _fill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Haptics.selection();
              onTap();
            },
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTabs() {
    const tabs = ['Loadout', 'Badges', 'Squad'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: const ShapeDecoration(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          color: _fill,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment(-1 + _profileTab * 1.0, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / tabs.length,
                heightFactor: 1,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: ContinuousRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                      side: BorderSide(
                        color: _green.withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                    ),
                    color: const Color(0xFF3A3A3D),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final (i, label) in tabs.indexed)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_profileTab == i) return;
                        Haptics.selection();
                        setState(() => _profileTab = i);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: _text(
                            14,
                            _profileTab == i ? Colors.white : _secondary,
                            weight: _profileTab == i
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// What's still missing from the profile, in the order we nudge for it.
  List<String> _missingProfileFields(model.User user) {
    final e = user.contact?.electronicAddress;
    final p = user.contact?.physicalAddress;
    bool empty(String? v) => (v ?? '').trim().isEmpty;
    return [
      if (empty(user.gameUserName)) 'game username',
      if (empty(user.name)) 'name',
      if (empty(user.gender)) 'gender',
      if (empty(user.dob)) 'date of birth',
      if (empty(e?.emailId)) 'email',
      if (empty(e?.mobileNo)) 'mobile number',
      if (empty(p?.addressLine1)) 'address',
      if (empty(p?.state)) 'state',
      if (empty(p?.country)) 'country',
    ];
  }

  Widget _buildGamePassport() {
    return Obx(() {
      final user = userController.user.value;
      const total = 9;
      final missing = _missingProfileFields(user);
      final progress = (total - missing.length) / total;
      final pct = (progress * 100).round();
      final complete = missing.isEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () {
            Haptics.selection();
            Get.to(() => const ProfileView());
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: _appleCard(
              radius: 44,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF17261B), _card],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _iconTile(Icons.badge_rounded, _green, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game passport',
                            style: _text(
                              16,
                              Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            complete
                                ? 'Ready for LFG, squads and ranked'
                                : 'Add your ${missing.first} to finish',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(12.5, _secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    complete
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: _green,
                            size: 24,
                          )
                        : Text(
                            '$pct%',
                            style: _text(17, _green, weight: FontWeight.w700),
                          ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _secondary,
                      size: 22,
                    ),
                  ],
                ),
                if (!complete) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 6,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: _fill),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.04, 1.0),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1E9E3E), _green],
                                ),
                              ),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProfileTabContent(String email) {
    switch (_profileTab) {
      case 1:
        return _buildBadgesTab();
      case 2:
        return _buildSquadTab();
      default:
        return _buildFeatureGrid(email);
    }
  }

  Widget _buildBadgesTab() {
    final referrals = userController.user.value.referralCount ?? 0;
    return FutureBuilder<HostVerification?>(
      future: _hostVerification,
      builder: (context, snapshot) {
        final verifiedHost =
            snapshot.data?.status == HostVerificationStatus.verified;
        final badges = [
          (
            'OG Player',
            'HASH account ready',
            Icons.sports_esports_rounded,
            _green,
            true,
          ),
          (
            'Squad Builder',
            'Refer 3 players · $referrals/3',
            Icons.groups_rounded,
            const Color(0xFF0A84FF),
            referrals >= 3,
          ),
          (
            'Tourney Host',
            'Become a verified host',
            Icons.workspace_premium_rounded,
            const Color(0xFFFF9F0A),
            verifiedHost,
          ),
          (
            'Clutch Mode',
            'Win a tournament',
            Icons.bolt_rounded,
            const Color(0xFFFF375F),
            false,
          ),
        ];
        final unlocked = badges.where((b) => b.$5).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '$unlocked of ${badges.length} unlocked',
                style: _text(13, _secondary, weight: FontWeight.w500),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final (title, hint, icon, tint, isOn) = badges[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _appleCard(
                    radius: 44,
                    border: isOn ? _hint : const Color(0x14FFFFFF),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isOn
                          ? [tint.withValues(alpha: 0.22), _card]
                          : const [Color(0xFF161618), Color(0xFF121214)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          isOn
                              ? _iconTile(icon, tint)
                              : Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const ShapeDecoration(
                                    shape: ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(20),
                                      ),
                                    ),
                                    color: _fill,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white30,
                                    size: 19,
                                  ),
                                ),
                          const Spacer(),
                          Icon(
                            isOn
                                ? Icons.check_circle_rounded
                                : Icons.lock_rounded,
                            size: 18,
                            color: isOn ? _green : Colors.white24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          15,
                          isOn ? Colors.white : Colors.white54,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOn ? 'Unlocked' : hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          12,
                          isOn ? _green : Colors.white38,
                          weight: isOn ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSquadTab() {
    return StreamBuilder<List<FriendRelationship>>(
      stream: _friendService.watchRelationships(),
      builder: (context, snapshot) {
        final uid = _friendService.currentUid ?? '';
        final relationships = snapshot.data ?? const [];
        final friends = relationships
            .where((item) => item.status == 'accepted')
            .length;
        final requests = relationships
            .where((item) => item.isIncoming(uid))
            .length;
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: _appleCard(
            radius: 48,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF16233A), _card],
            ),
          ),
          child: Column(
            children: [
              _iconTile(
                Icons.groups_2_rounded,
                const Color(0xFF0A84FF),
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                friends == 1
                    ? '1 player in your squad'
                    : '$friends players in your squad',
                textAlign: TextAlign.center,
                style: _text(17, Colors.white, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                requests > 0
                    ? '$requests request${requests == 1 ? '' : 's'} waiting for you'
                    : 'Stack up. Queue together. Run it back.',
                textAlign: TextAlign.center,
                style: _text(13, requests > 0 ? _green : _secondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _profileAction(
                      label: 'Find players',
                      icon: CupertinoIcons.person_add,
                      onTap: () =>
                          Get.to(() => const FriendsView(initialTab: 2)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileAction(
                      label: 'Open squad',
                      icon: CupertinoIcons.person_2_fill,
                      primary: true,
                      onTap: () => Get.to(() => const FriendsView()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid(String email) {
    final features = [
      (
        'My tournaments',
        'Compete & manage',
        Icons.emoji_events_rounded,
        _green,
        () => Get.toNamed(AppRoutes.MY_TOURNAMENTS),
      ),
      (
        'Friends',
        'Your gaming squad',
        CupertinoIcons.person_2_fill,
        const Color(0xFF0A84FF),
        () => Get.to(() => const FriendsView()),
      ),
      (
        'HASH Wallet',
        'Coins & rewards',
        CupertinoIcons.creditcard_fill,
        const Color(0xFFFF9F0A),
        () => Get.toNamed(AppRoutes.WALLET),
      ),
      (
        'Refer squad',
        'Invite & earn',
        CupertinoIcons.gift_fill,
        const Color(0xFFBF5AF2),
        () {
          segmentService.onReferralViewed(email: email);
          Get.to(() => ReferralViewWithController(email: email));
        },
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final (title, subtitle, icon, tint, onTap) = features[index];
        return Material(
          color: Colors.transparent,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(44)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: _appleCard(
              radius: 44,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withValues(alpha: 0.2), _card],
              ),
            ),
            child: InkWell(
              onTap: () {
                Haptics.selection();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconTile(icon, tint, size: 38),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          color: _secondary,
                          size: 18,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(16, Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(12.5, _secondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _profileHandle() {
    final gameTag = userController.user.value.gameUserName?.trim() ?? '';
    if (gameTag.isNotEmpty) return '@$gameTag';
    final name = userController.user.value.name?.trim() ?? '';
    if (name.isEmpty) return 'hash.gamer';
    return '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}';
  }

  Future<void> _shareProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = userController.user.value.name?.trim();
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ${name?.isNotEmpty == true ? name : 'my'} gamer profile on HASH 🎮\n'
            'https://hashforgamers.com/profile/$uid',
        subject: 'HASH gamer profile',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _showSettingsSheet(String email) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Settings and activity',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionLabel('Your account'),
                _buildProfileOption(
                  icon: CupertinoIcons.person,
                  title: 'Edit profile',
                  subtitle: 'Personal details and game identity',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Get.to(() => const ProfileView());
                  },
                ),
                _buildProfileOption(
                  icon: CupertinoIcons.person_2,
                  title: 'Friends and requests',
                  subtitle: 'Manage your Hash connections',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Get.to(() => const FriendsView());
                  },
                ),
                _buildProfileOption(
                  icon: CupertinoIcons.gift,
                  title: 'Refer & Earn',
                  subtitle: 'Invite your squad and earn rewards',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    segmentService.onReferralViewed(email: email);
                    Get.to(() => ReferralViewWithController(email: email));
                  },
                ),
                const SizedBox(height: 8),
                _buildSectionLabel('Support and information'),
                _buildProfileOption(
                  icon: CupertinoIcons.question_circle,
                  title: 'Need help',
                  subtitle: 'Bookings, payments and account support',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    segmentService.onHelpRequested(email: email);
                    Get.to(() => NeedHelpPage());
                  },
                ),
                _buildProfileOption(
                  icon: CupertinoIcons.info_circle,
                  title: 'About HASH',
                  subtitle: 'Hash For Gamers',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Get.to(() => AboutPage());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildLogoutButton()),
                    const SizedBox(width: 10),
                    _buildDeleteButton(userController),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x2216A34A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xff00DC00), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await GoogleSignIn.instance.initialize();
            await GoogleSignIn.instance.signOut();
            await locator<AuthDataRepository>().clearTokens();
            await FirebaseAuth.instance.signOut(); // clear Firebase session

            final prefs = await SharedPreferences.getInstance();
            await prefs.clear(); // remove all local data

            if (Get.isRegistered<WalletController>()) {
              Get.find<WalletController>().clearSession();
            }
            if (mounted) {
              context.read<HashCoinCubit>().reset();
            }
            userController.clearSession();

            Get.offAllNamed(AppRoutes.LOGIN);
          } catch (e) {
            Get.snackbar(
              'Logout Error',
              e.toString(),
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff00DC00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          CupertinoIcons.square_arrow_right,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          'Logout',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(UserController userController) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Tooltip(
        message: 'Delete account',
        child: Material(
          color: const Color(0xFF2A1515),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () =>
                showBlackCupertinoDeleteDialog(context, userController),
            borderRadius: BorderRadius.circular(12),
            child: const Center(
              child: Icon(
                CupertinoIcons.delete_solid,
                color: Color(0xFFEE6A6A),
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showDeleteAccountDialog(
    BuildContext context,
    UserController userController,
  ) async {
    bool isChecked = false;
    int secondsLeft = 10;
    ValueNotifier<int> timerNotifier = ValueNotifier(secondsLeft);
    ValueNotifier<bool> acceptNotifier = ValueNotifier(false);

    // Start countdown
    Future(() async {
      while (secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        secondsLeft--;
        timerNotifier.value = secondsLeft;
      }
    });

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoTheme(
          data: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: CupertinoColors.systemRed,
            scaffoldBackgroundColor: CupertinoColors.black,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return CupertinoAlertDialog(
                title: const Text(
                  "⚠️ Delete Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                content: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "This action is permanent.\n\n"
                      "Once deleted, you cannot create another account using the same EMAIL/NUMBER for 30 days.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Countdown
                    ValueListenableBuilder<int>(
                      valueListenable: timerNotifier,
                      builder: (_, value, __) {
                        return Text(
                          value > 0
                              ? "⏳ Please wait $value sec..."
                              : "✅ You may now continue",
                          style: TextStyle(
                            color: value > 0
                                ? CupertinoColors.systemYellow
                                : CupertinoColors.activeGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Checkbox replacement
                    ValueListenableBuilder<int>(
                      valueListenable: timerNotifier,
                      builder: (_, value, __) {
                        return GestureDetector(
                          onTap: value == 0
                              ? () {
                                  setState(() {
                                    isChecked = !isChecked;
                                    acceptNotifier.value = isChecked;
                                  });
                                }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isChecked
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                size: 24,
                                color: value == 0
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.inactiveGray,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "I understand the risk",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: value == 0
                                      ? CupertinoColors.white
                                      : CupertinoColors.inactiveGray,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: acceptNotifier,
                    builder: (_, accepted, __) {
                      return CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: accepted
                            ? () async {
                                // Track account deleted requested event
                                segmentService.onAccountDeletedRequested(
                                  email:
                                      userController
                                          .user
                                          .value
                                          .contact
                                          ?.electronicAddress
                                          ?.emailId ??
                                      '',
                                );

                                Navigator.of(context).pop();
                                final success = await userController
                                    .deleteUser();
                                if (success) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  Get.offAllNamed(AppRoutes.LOGIN);
                                } else {
                                  Get.snackbar(
                                    "Error",
                                    "Failed to delete account",
                                    backgroundColor: CupertinoColors.systemRed,
                                    colorText: CupertinoColors.white,
                                  );
                                }
                              }
                            : null,
                        child: const Text("Delete"),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// --- drop this anywhere accessible (e.g., same file, bottom) ---
Future<void> showBlackCupertinoDeleteDialog(
  BuildContext context,
  UserController userController,
) async {
  int secondsLeft = 10;
  final timerVN = ValueNotifier<int>(secondsLeft);
  final acceptedVN = ValueNotifier<bool>(false);

  // Countdown (outside widget tree; cancel on close)
  final timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (secondsLeft <= 0) {
      t.cancel();
    } else {
      secondsLeft--;
      timerVN.value = secondsLeft;
    }
  });

  await showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark, // black dialog
        primaryColor: CupertinoColors.systemRed,
      ),
      child: WillPopScope(
        onWillPop: () async => false, // block back
        child: CupertinoAlertDialog(
          title: const Text(
            '⚠️ Delete Account',
            style: TextStyle(
              color: CupertinoColors.systemRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'This action is permanent.\n\n'
                'After deleting, you CANNOT create another account '
                'with the same EMAIL/NUMBER for 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.white, fontSize: 15),
              ),
              const SizedBox(height: 16),

              // Countdown
              ValueListenableBuilder<int>(
                valueListenable: timerVN,
                builder: (_, v, __) => Text(
                  v > 0 ? 'Please wait $v sec…' : 'You may now continue.',
                  style: TextStyle(
                    color: v > 0
                        ? CupertinoColors.systemYellow
                        : CupertinoColors.activeGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // “I understand the risk” toggle (enabled after timer)
              ValueListenableBuilder<int>(
                valueListenable: timerVN,
                builder: (_, v, __) {
                  final enabled = v == 0;
                  return GestureDetector(
                    onTap: enabled
                        ? () => acceptedVN.value = !acceptedVN.value
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: acceptedVN,
                          builder: (_, ok, __) => Icon(
                            ok
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: enabled
                                ? (ok
                                      ? CupertinoColors.activeGreen
                                      : CupertinoColors.white)
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'I understand the risk',
                          style: TextStyle(
                            color: enabled
                                ? CupertinoColors.white
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                if (timer.isActive) timer.cancel();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
            ),
            ValueListenableBuilder2<bool, int>(
              first: acceptedVN,
              second: timerVN,
              builder: (_, accepted, v, __) {
                final canDelete = accepted && v == 0;
                return CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: canDelete
                      ? () async {
                          if (timer.isActive) timer.cancel();
                          Navigator.of(context).pop();

                          final ok = await userController.deleteUser();
                          if (ok) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Get.offAllNamed(AppRoutes.LOGIN);
                          } else {
                            Get.snackbar(
                              'Error',
                              'Failed to delete account',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        }
                      : null,
                  child: Text(
                    v > 0 ? 'Delete ($v)' : 'Delete',
                    style: TextStyle(
                      color: canDelete
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemRed.withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  if (timer.isActive) timer.cancel(); // safety
}

/// Small helper to listen to two notifiers at once
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (ctx, b, ___) => builder(ctx, a, b, child),
      ),
    );
  }
}
