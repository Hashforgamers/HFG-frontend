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
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/widgets/glow_neon_loader.dart';
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
        centerTitle: false,
        title: Obx(
          () => Text(
            _profileHandle(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share profile',
            onPressed: _shareProfile,
            icon: const Icon(CupertinoIcons.paperplane, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettingsSheet(email),
            icon: const Icon(CupertinoIcons.line_horizontal_3),
          ),
          const SizedBox(width: 6),
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
            const SizedBox(height: 10),
            _buildProfileHeader(userController),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _profileAction(
                      label: 'Edit profile',
                      onTap: () => Get.to(() => ProfileView()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileAction(
                      label: 'Share profile',
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
            const SizedBox(height: 24),
            _buildGamingHighlights(),
            const SizedBox(height: 14),
            _buildGamePassport(),
            const SizedBox(height: 22),
            _buildProfileTabs(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: _buildProfileTabContent(email),
            ),
          ],
        ),
      ),
    );
  }

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
      final gameTag = user.gameUserName?.trim() ?? '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 94,
                  height: 94,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xff00DC00),
                        Color(0xff7CFF6B),
                        Color(0xff00DC00),
                        Color(0xff087F23),
                        Color(0xff00DC00),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF151515),
                      backgroundImage: hasPhoto
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: hasPhoto
                          ? null
                          : const Icon(
                              CupertinoIcons.person_fill,
                              color: Color(0xff00DC00),
                              size: 38,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
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
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _profileStat(
                            '$friends',
                            'Friends',
                            () =>
                                Get.to(() => const FriendsView(initialTab: 0)),
                          ),
                          _profileStat(
                            '$requests',
                            'Requests',
                            () =>
                                Get.to(() => const FriendsView(initialTab: 1)),
                          ),
                          _profileStat(
                            gameTag.isEmpty ? '—' : '1',
                            'Game ID',
                            () => Get.to(() => ProfileView()),
                          ),
                        ],
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
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
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
                        color: Color(0xFF3897F0),
                        size: 18,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              gameTag.isEmpty ? 'HASH gamer' : '@$gameTag',
              style: GoogleFonts.inter(
                color: gameTag.isEmpty
                    ? Colors.white54
                    : const Color(0xff00DC00),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Play. Compete. Connect. 🎮',
              style: GoogleFonts.inter(color: Colors.white, height: 1.35),
            ),
          ],
        ),
      );
    });
  }

  Widget _profileStat(String value, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileAction({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF171717),
          side: const BorderSide(color: Colors.white12),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
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
        width: 40,
        height: 36,
        child: Material(
          color: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: const BorderSide(color: Colors.white12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildGamingHighlights() {
    final highlights = [
      (
        CupertinoIcons.game_controller,
        'Game ID',
        () => Get.to(() => ProfileView()),
      ),
      (
        Icons.emoji_events_outlined,
        'Tournaments',
        () => Get.toNamed(AppRoutes.MY_TOURNAMENTS),
      ),
      (
        CupertinoIcons.person_2,
        'Squad',
        () => Get.to(() => const FriendsView()),
      ),
      (CupertinoIcons.gift, 'Rewards', () => Get.toNamed(AppRoutes.WALLET)),
    ];
    return SizedBox(
      height: 89,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: highlights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final item = highlights[index];
          return GestureDetector(
            onTap: item.$3,
            child: SizedBox(
              width: 67,
              child: Column(
                children: [
                  Container(
                    width: 61,
                    height: 61,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFF151A15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.$1,
                        color: const Color(0xff00DC00),
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12),
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          _profileTabButton(0, Icons.grid_on_rounded, 'LOADOUT'),
          _profileTabButton(1, Icons.emoji_events_outlined, 'BADGES'),
          _profileTabButton(2, CupertinoIcons.person_2, 'SQUAD'),
        ],
      ),
    );
  }

  Widget _profileTabButton(int index, IconData icon, String label) {
    final selected = _profileTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _profileTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: selected ? 58 : 0,
              color: const Color(0xff00DC00),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamePassport() {
    return Obx(() {
      final user = userController.user.value;
      final gameId = user.gameUserName?.trim() ?? '';
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18251A), Color(0xFF12131A)],
          ),
          border: Border.all(color: const Color(0x4400DC00)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0x2200DC00),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: Color(0xFF00DC00),
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HASH GAME PASSPORT',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00DC00),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gameId.isEmpty ? 'LOADOUT NOT SET' : '@$gameId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    gameId.isEmpty
                        ? 'Add your gamer ID to get discovered.'
                        : 'Ready for LFG, squads and ranked.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit loadout',
              onPressed: () => Get.to(() => ProfileView()),
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
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
            'OG PLAYER',
            'HASH account ready',
            Icons.sports_esports_rounded,
            true,
          ),
          (
            'SQUAD BUILDER',
            'Refer 3 players',
            Icons.groups_rounded,
            referrals >= 3,
          ),
          (
            'TOURNEY HOST',
            'Verified HASH host',
            Icons.workspace_premium_rounded,
            verifiedHost,
          ),
          ('CLUTCH MODE', 'Tournament win', Icons.bolt_rounded, false),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: badge.$4
                    ? const Color(0xFF172219)
                    : const Color(0xFF131313),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: badge.$4 ? const Color(0x4400DC00) : Colors.white10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    badge.$3,
                    color: badge.$4 ? const Color(0xFF00DC00) : Colors.white24,
                  ),
                  const Spacer(),
                  Text(
                    badge.$1,
                    style: GoogleFonts.inter(
                      color: badge.$4 ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    badge.$4 ? 'UNLOCKED' : badge.$2,
                    style: GoogleFonts.inter(
                      color: badge.$4
                          ? const Color(0xFF00DC00)
                          : Colors.white30,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          },
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141719),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.groups_2_rounded,
                color: Color(0xFF5DA9FF),
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                '$friends in your squad · $requests pending',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stack up. Queue together. Run it back.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const FriendsView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DA9FF),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'OPEN SQUAD',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
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
        const Color(0xFF1B321D),
        () => Get.toNamed(AppRoutes.MY_TOURNAMENTS),
      ),
      (
        'Friends',
        'Your gaming squad',
        CupertinoIcons.person_2_fill,
        const Color(0xFF17243A),
        () => Get.to(() => const FriendsView()),
      ),
      (
        'HASH Wallet',
        'Coins & rewards',
        CupertinoIcons.creditcard_fill,
        const Color(0xFF332A17),
        () => Get.toNamed(AppRoutes.WALLET),
      ),
      (
        'Refer squad',
        'Invite & earn',
        CupertinoIcons.gift_fill,
        const Color(0xFF301D36),
        () {
          segmentService.onReferralViewed(email: email);
          Get.to(() => ReferralViewWithController(email: email));
        },
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = features[index];
        return Material(
          color: item.$4,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: item.$5,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.$3,
                      color: const Color(0xff00DC00),
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
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
                    Get.to(() => ProfileView());
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
            final googleSignIn = GoogleSignIn();
            if (await googleSignIn.isSignedIn()) {
              await googleSignIn.signOut();
            }
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
