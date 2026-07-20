import 'package:animated_glitch/animated_glitch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/models/gamer_profile_model.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_details_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournament_card_share_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/gamer_profile_story_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_team_members_view.dart';
import 'package:hash/app/modules/home/widgets/optimized_app_bar.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/app/modules/community/models/host_verification.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';
import 'package:hash/core/utils/haptics.dart';

import '../../../data/services/user_controller.dart';
import '../cubit/tournament_home_cubit.dart';
import 'package:hash/core/utils/app_logger.dart';

class TournamentsHomeView extends StatefulWidget {
  const TournamentsHomeView({super.key});

  @override
  State<TournamentsHomeView> createState() => _TournamentsHomeViewState();
}

class _TournamentsHomeViewState extends State<TournamentsHomeView> {
  late final TournamentHomeCubit _cubit;
  late final Future<HostVerification?> _hostRegistration;
  late final AnimatedGlitchController _gamerProfileGlitch;
  final SquadMissionsService _squadMissionsService =
      locator<SquadMissionsService>();

  final userController = Get.find<UserController>();
  double _hostSheetUpwardDrag = 0;
  bool _hostDragThresholdReached = false;
  bool _hostSheetOpening = false;

  @override
  void initState() {
    super.initState();
    _cubit = TournamentHomeCubit();
    _hostRegistration = CommunityApi().getMyHostVerification();
    _gamerProfileGlitch = AnimatedGlitchController(
      frequency: const Duration(milliseconds: 1800),
      chance: 32,
      level: .65,
    );
    _cubit.fetchTournaments(forceRefresh: false);
  }

  @override
  void dispose() {
    _gamerProfileGlitch.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomSheet: _hostSheetPeek(),
        body: RefreshIndicator(
          color: const Color(0xFF00DC00),
          backgroundColor: const Color(0xFF121212),
          onRefresh: () => _cubit.fetchTournaments(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const OptimizedAppBar(
                gradientBottomColor: Color(0xFFFFA43A),
                avatarBorderColor: Color(0xFFFFA43A),
                showModeToggle: false,
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<TournamentHomeCubit, TournamentHomeState>(
                  builder: (context, state) {
                    if (state is TournamentHomeLoading) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72,
                        child: const Center(child: TournamentsLoader.screen()),
                      );
                    } else if (state is TournamentHomeLoaded) {
                      return _buildBodyContent(
                        state.tournaments,
                        state.joinableTournaments,
                        state.myTeams,
                        state.gamerProfile,
                      );
                    } else if (state is TournamentHomeError) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72,
                        child: Center(
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    List<TournamentModel> joinedTournaments,
    List<TournamentModel> joinableTournaments,
    List<Map<String, dynamic>> myTeams,
    GamerProfileModel? gamerProfile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _sectionTitle('Discover tournaments', subtitle: 'Find your next match'),
        const SizedBox(height: 12),
        const _TabsSection(),
        const SizedBox(height: 16),
        _buildTournamentList(
          joinableTournaments,
          emptyText: 'No tournaments available to join',
          showJoinedTag: true,
        ),
        if (joinedTournaments.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionTitle('Joined tournaments'),
          const SizedBox(height: 14),
          _buildTournamentList(
            joinedTournaments,
            emptyText: 'No joined tournaments in this section',
          ),
        ],
        const SizedBox(height: 28),
        _buildMyTeamsSection(myTeams),
        if (myTeams.isNotEmpty) const SizedBox(height: 28),
        _sectionTitle('Gamer profile', subtitle: 'Your tournament journey'),
        const SizedBox(height: 12),
        _buildGamerProfile(gamerProfile),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
      ],
    ),
  );

  Widget _hostSheetPeek() => Material(
    color: Colors.transparent,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openHostSheet,
      onVerticalDragStart: (_) {
        _hostSheetUpwardDrag = 0;
        _hostDragThresholdReached = false;
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < 0) {
          _hostSheetUpwardDrag += -details.delta.dy;
          if (_hostSheetUpwardDrag >= 18 && !_hostDragThresholdReached) {
            _hostDragThresholdReached = true;
            Haptics.selection();
          }
        }
      },
      onVerticalDragEnd: (_) {
        final shouldOpen = _hostSheetUpwardDrag >= 18;
        _hostSheetUpwardDrag = 0;
        if (shouldOpen) _openHostSheet();
      },
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF242424), Color(0xFF101010), Colors.black],
            stops: [0, .62, 1],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 10),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Host tournaments',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Build hype. Earn from every event.',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white54,
                        size: 19,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openHostSheet() async {
    if (_hostSheetOpening) return;
    _hostSheetOpening = true;
    await Haptics.medium();
    try {
      await _showHostTournamentSheet();
    } finally {
      _hostSheetOpening = false;
      await Haptics.light();
    }
  }

  Future<void> _showHostTournamentSheet() async {
    final verification = CommunityApi().getMyHostVerification();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .52,
        minChildSize: .40,
        maxChildSize: .88,
        expand: false,
        snap: true,
        snapSizes: const [.52, .88],
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF242424), Color(0xFF101010), Colors.black],
              stops: [0, .72, 1],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: FutureBuilder<HostVerification?>(
            future: verification,
            builder: (context, snapshot) {
              final isVerified =
                  snapshot.data?.status == HostVerificationStatus.verified;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF444444),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        isVerified ? 'Your host command centre' : 'Host on ',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!isVerified)
                        const HashWordmark(fontSize: 14, letterSpacing: 2.2),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    isVerified
                        ? 'Create tournaments, grow registrations, and track what you earn.'
                        : 'Turn your gaming community into tournaments—and earn every time you host.',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _hostSheetBenefit(
                    Icons.emoji_events_outlined,
                    'Create unlimited tournaments',
                    'Choose the game, format, entry fee, and prize split.',
                  ),
                  _hostSheetBenefit(
                    Icons.groups_2_outlined,
                    'Bring your players together',
                    'Share one publicity poster and manage registrations.',
                  ),
                  _hostSheetBenefit(
                    Icons.account_balance_wallet_outlined,
                    'Earn from every event',
                    'Track collections and your host commission in one place.',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          snapshot.connectionState == ConnectionState.waiting
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              Get.toNamed(
                                isVerified
                                    ? AppRoutes.HOST_DASHBOARD
                                    : AppRoutes.HOST_ONBOARDING,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isVerified
                                  ? 'Open Host Dashboard'
                                  : 'Become a verified host',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  if (!isVerified &&
                      snapshot.connectionState != ConnectionState.waiting) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Verification keeps paid tournaments safe for every player.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hostSheetBenefit(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTournamentList(
    List<TournamentModel> tournaments, {
    required String emptyText,
    bool showJoinedTag = false,
  }) {
    if (tournaments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          emptyText,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 292,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tournaments.length,
          itemBuilder: (context, index) => _buildTournamentCard(
            tournaments[index],
            showJoinedTag: showJoinedTag,
          ),
          separatorBuilder: (context, index) => const SizedBox(width: 12),
        ),
      ),
    );
  }

  Widget _buildMyTeamsSection(List<Map<String, dynamic>> myTeams) {
    if (myTeams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My teams',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ...myTeams.take(6).map((team) {
            final tournamentValue = team['tournament'] ?? team['event'];
            final tournament = tournamentValue is Map
                ? Map<String, dynamic>.from(tournamentValue)
                : const <String, dynamic>{};
            final teamName = (team['team_name'] ?? team['name'] ?? 'Team')
                .toString();
            final teamId =
                (team['team_id'] ?? team['registration_id'] ?? team['id'] ?? '')
                    .toString();
            final eventId =
                (team['event_id'] ??
                        tournament['event_id'] ??
                        tournament['id'] ??
                        '')
                    .toString();
            final tournamentName =
                (tournament['name'] ??
                        tournament['title'] ??
                        team['tournament_name'] ??
                        team['event_name'] ??
                        '')
                    .toString()
                    .trim();
            final tournamentLabel = tournamentName.isNotEmpty
                ? tournamentName
                : eventId.isNotEmpty
                ? 'Tournament $eventId'
                : 'Tournament';
            final tournamentImage =
                (tournament['image_url'] ??
                        tournament['imageUrl'] ??
                        tournament['banner'] ??
                        tournament['banner_image_url'] ??
                        '')
                    .toString()
                    .trim();
            final role = (team['role'] ?? '').toString();
            final count = (team['member_count'] ?? 0).toString();
            final roleText = role.isEmpty ? 'Member' : role;
            final badgeText = roleText.toLowerCase().contains('captain')
                ? 'Captain'
                : 'Member';
            return InkWell(
              borderRadius: BorderRadius.zero,
              onTap: () {
                if (eventId.isEmpty || teamId.isEmpty) return;
                Get.to(
                  () => TournamentsTeamMembersView(
                    eventId: eventId,
                    teamId: teamId,
                    teamName: teamName,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF292929))),
                ),
                child: Row(
                  children: [
                    tournamentImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: tournamentImage.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: tournamentImage,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => _proofAvatar(
                                        seed: teamName,
                                        icon: Icons.groups_rounded,
                                        color: const Color(0xFFFF7A00),
                                      ),
                                    )
                                  : Image.asset(
                                      tournamentImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _proofAvatar(
                                        seed: teamName,
                                        icon: Icons.groups_rounded,
                                        color: const Color(0xFFFF7A00),
                                      ),
                                    ),
                            ),
                          )
                        : _proofAvatar(
                            seed: teamName,
                            icon: Icons.groups_rounded,
                            color: const Color(0xFFFF7A00),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFFFFD600),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Joined · $tournamentLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _proofChip(
                                label: badgeText,
                                icon: badgeText == 'Captain'
                                    ? Icons.verified_rounded
                                    : Icons.shield_moon_rounded,
                                color: badgeText == 'Captain'
                                    ? const Color(0xFFFFB347)
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              StreamBuilder<int>(
                                stream: _squadMissionsService
                                    .watchCurrentStreakForSquad(
                                      squadKey: teamId,
                                    ),
                                builder: (context, snap) {
                                  final streak = snap.data ?? 0;
                                  return _proofChip(
                                    label: '${streak}d',
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFFF8A00),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count players',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel t, {bool showJoinedTag = false}) {
    final dateFormat = DateFormat('d MMM');
    final start = t.startDate;
    final end = t.endDate;
    final dateRange = (start != null && end != null)
        ? '${dateFormat.format(start)} - ${dateFormat.format(end)}'
        : 'Date TBA';
    final String imagePath = t.imageUrl;
    final ImageProvider tournamentImage = imagePath.startsWith('http')
        ? NetworkImage(imagePath)
        : AssetImage(imagePath) as ImageProvider;
    return GestureDetector(
      onTap: () {
        if (t.source == 'community') {
          Get.toNamed(
            AppRoutes.TOURNAMENT_DETAIL,
            arguments: {'id': t.id, 'can_manage': t.canManage},
          );
        } else {
          Get.to(() => TournamentsDetailsView(tournament: t));
        }
      },
      child: SizedBox(
        width: 164,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 164,
                height: 224,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: tournamentImage, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66000000)],
                        ),
                      ),
                    ),
                    if (showJoinedTag && t.isJoined)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B84A),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ALREADY JOINED',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: .68),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Get.to(
                            () => TournamentCardShareView(tournament: t),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.ios_share_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Row(
                        children: [
                          Text(
                            t.statusLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: _statusColor(t.status),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            t.entryFee,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              dateRange,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _proofAvatar({
    required String seed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.92), color.withValues(alpha: 0.6)],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }

  Widget _proofChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.live:
        return const Color(0xFFE74C3C);
      case TournamentStatus.upcoming:
        return const Color(0xFF3498DB);
      case TournamentStatus.completed:
        return const Color(0xFF7F8C8D);
      case TournamentStatus.unknown:
        return const Color(0xFF5D5D5D);
    }
  }

  Widget _buildGamerProfile(GamerProfileModel? profile) {
    final displayName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName.trim()
        : 'Gamer';
    final username = profile?.gameUsername.trim() ?? '';
    final stats = profile?.stats;
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        const horizontalInset = 0.0;
        final cardWidth = outerConstraints.maxWidth - (horizontalInset * 2);
        return SizedBox(
          width: outerConstraints.maxWidth,
          height: cardWidth / 2,
          child: Stack(
            children: [
              AnimatedGlitch(
                controller: _gamerProfileGlitch,
                showColorChannels: true,
                showDistortions: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalInset,
                  ),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;
                        final scale = (width / 360).clamp(1.0, 1.22);
                        final avatarSize = height * .42;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/gamer_profile_holographic_bg.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              ),
                            ),
                            Positioned(
                              left: width * .080,
                              top: height * .225,
                              width: avatarSize,
                              height: avatarSize,
                              child: _buildOptimizedUserAvatar(
                                profile?.avatarUrl.isNotEmpty == true
                                    ? profile!.avatarUrl
                                    : userController.user.value.photoUrl,
                                size: avatarSize,
                              ),
                            ),
                            Positioned(
                              left: width * .31,
                              top: height * .24,
                              width: width * .40,
                              height: height * .34,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<HostVerification?>(
                                    future: _hostRegistration,
                                    builder: (context, snapshot) {
                                      final status = snapshot.data?.status;
                                      final isRegistered =
                                          status ==
                                              HostVerificationStatus.pending ||
                                          status ==
                                              HostVerificationStatus.verified;
                                      return Row(
                                        children: [
                                          Text(
                                            'YOU',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 9.5 * scale,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.3,
                                            ),
                                          ),
                                          if (isRegistered) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.verified_rounded,
                                              color: Color(0xFF2196F3),
                                              size: 14 * scale,
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.2,
                                    ),
                                  ),
                                  if (username.isNotEmpty)
                                    Text(
                                      '@$username',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11.2 * scale,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (profile?.host.isVerified == true &&
                                profile!.host.tier.isNotEmpty)
                              Positioned(
                                right: width * .065,
                                top: height * .35,
                                width: width * .20,
                                child: Text(
                                  profile.host.tier.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9.5 * scale,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            Positioned(
                              left: width * .105,
                              right: width * .075,
                              top: height * .645,
                              bottom: height * .095,
                              child: Row(
                                children: [
                                  _profileStat(
                                    '${stats?.joined ?? 0}',
                                    'PLAYED',
                                    Icons.sports_esports_outlined,
                                    scale,
                                  ),
                                  _profileDivider(scale),
                                  _profileStat(
                                    '${stats?.wins ?? 0}',
                                    'WINS',
                                    Icons.emoji_events_outlined,
                                    scale,
                                  ),
                                  _profileDivider(scale),
                                  _profileStat(
                                    '${stats?.podiumFinishes ?? 0}',
                                    'PODIUMS',
                                    Icons.leaderboard_outlined,
                                    scale,
                                  ),
                                  _profileDivider(scale),
                                  _profileStat(
                                    '${stats?.hosted ?? 0}',
                                    'HOSTED',
                                    Icons.workspace_premium_outlined,
                                    scale,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: .72),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        Get.to(() => GamerProfileStoryView(profile: profile)),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.ios_share_rounded,
                        color: Color(0xFFFFD600),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileDivider(double scale) =>
      Container(width: 1, height: 32 * scale, color: const Color(0xFFFF1493));

  Widget _profileStat(
    String value,
    String label,
    IconData icon,
    double scale,
  ) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF1493), size: 14 * scale),
            SizedBox(width: 3 * scale),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14.5 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3 * scale),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 8.2 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: .55,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildOptimizedUserAvatar(String? photoUrl, {double size = 70}) {
    final effectivePhoto = (photoUrl ?? '').trim().isNotEmpty
        ? photoUrl!.trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA6FF00).withValues(alpha: .12),
            blurRadius: 14,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: effectivePhoto.isNotEmpty
            ? CachedNetworkImageProvider(
                effectivePhoto,
                errorListener: (error) =>
                    AppLogger.d('Avatar image error: $error'),
              )
            : null,
        backgroundColor: Colors.white,
        child: effectivePhoto.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.black54)
            : null,
      ),
    );
  }
}

//---------------Tab button & TabsSection-------------------
class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;

  const _TabButton({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        color: isSelected ? null : const Color(0xFF4A4A4A),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFFFD900), Color(0xFFFFA43A)],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.black : Colors.white70,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _TabsSection extends StatefulWidget {
  const _TabsSection();

  @override
  State<_TabsSection> createState() => _TabsSectionState();
}

class _TabsSectionState extends State<_TabsSection> {
  int selectedIndex = 0;
  final List<String> tabs = ['All', 'Upcoming', 'Live', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final text = tabs[index];
            final isSelected = selectedIndex == index;
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                    context.read<TournamentHomeCubit>().filterTournaments(text);
                  },
                  child: _TabButton(text: text, isSelected: isSelected),
                ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ),
      ),
    );
  }
}

//----------------------GradientText-------------------------
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.fontSize = 32,
    this.fontWeight = FontWeight.bold,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF9F9F9F),
          Color(0xFF9F9F9F),
          Color(0xFF3A3A3A),
          Color(0xFF3A3A3A),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}
