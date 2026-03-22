import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_details_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_team_members_view.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_app_bar.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';

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
  final SquadMissionsService _squadMissionsService =
      locator<SquadMissionsService>();

  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentHomeCubit();
    _cubit.fetchTournaments(forceRefresh: false);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     Get.to(const TournamentsDetailsView());
        //   },
        //   child: const Icon(Icons.arrow_forward),
        // ),
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          color: const Color(0xFFC06701),
          backgroundColor: const Color(0xFF121212),
          onRefresh: () => _cubit.fetchTournaments(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const TournamentsAppBar(),
              SliverToBoxAdapter(
                child: BlocBuilder<TournamentHomeCubit, TournamentHomeState>(
                  builder: (context, state) {
                    if (state is TournamentHomeLoading) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72,
                        child: const Center(child: TournamentsLoader.screen()),
                      );
                    } else if (state is TournamentHomeLoaded) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: _buildBodyContent(
                          state.tournaments,
                          state.joinableTournaments,
                          state.myTeams,
                        ),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Joined Tournaments",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _TabsSection(),
        const SizedBox(height: 16),
        _buildTournamentList(
          joinedTournaments,
          emptyText: 'No joined tournaments in this section',
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "All Tournaments (Join)",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildTournamentList(
          joinableTournaments,
          emptyText: 'No tournaments available to join',
        ),
        const SizedBox(height: 18),
        _buildMyTeamsSection(myTeams),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Your Position",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildYourPosition(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTournamentList(
    List<TournamentModel> tournaments, {
    required String emptyText,
  }) {
    if (tournaments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(emptyText, style: const TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 280,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tournaments.length,
          itemBuilder: (context, index) =>
              _buildTournamentCard(tournaments[index]),
          separatorBuilder: (context, index) => const SizedBox(width: 3),
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
            "My Teams",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...myTeams.take(6).map((team) {
            final teamName = (team['team_name'] ?? 'Team').toString();
            final teamId = (team['team_id'] ?? '').toString();
            final eventId = (team['event_id'] ?? '').toString();
            final role = (team['role'] ?? '').toString();
            final count = (team['member_count'] ?? 0).toString();
            final roleText = role.isEmpty ? 'Member' : role;
            final badgeText = roleText.toLowerCase().contains('captain')
                ? 'Captain'
                : 'Member';
            return InkWell(
              borderRadius: BorderRadius.circular(14),
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
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _proofAvatar(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '$count players',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildTournamentCard(TournamentModel t) {
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
    final topTeams = t.teams.take(3).toList();
    final topRank = t.teams.isNotEmpty ? t.teams.first.rank : '-';

    return GestureDetector(
      onTap: () {
        Get.to(() => TournamentsDetailsView(tournament: t));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 158,
                height: 208,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: tournamentImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(t.status).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    _proofChip(
                      label: '#$topRank',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFFFB347),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.entryFee,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (topTeams.isNotEmpty)
                Positioned(left: 8, bottom: 8, child: _avatarStack(topTeams)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 158,
            height: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateRange,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.teamMode,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarStack(List<dynamic> teams) {
    return SizedBox(
      width: 68,
      height: 22,
      child: Stack(
        children: List.generate(teams.length, (index) {
          final team = teams[index];
          final left = index * 16.0;
          final photoUrl = (team.photoUrl ?? '').toString();
          return Positioned(
            left: left,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: CircleAvatar(
                radius: 11,
                backgroundImage: photoUrl.startsWith('http')
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                backgroundColor: const Color(0xFF2C2C2C),
                child: photoUrl.startsWith('http')
                    ? null
                    : Text(
                        (team.name.isNotEmpty ? team.name[0] : 'T')
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          );
        }),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

  Widget _buildYourPosition() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        gradient: const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1D1D1F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const GradientText('238'),
          const SizedBox(width: 8),
          _buildOptimizedUserAvatar(userController.user.value.photoUrl),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person, color: Color(0xff00DC00), size: 16),
                  SizedBox(width: 4),
                  Text('You', style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.star, color: Color(0xff00DC00), size: 16),
                  SizedBox(width: 4),
                  Text('100 Points', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.emoji_events, color: Color(0xff00DC00), size: 16),
                  SizedBox(width: 4),
                  Text('2 Matches Won', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.north_east, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildOptimizedUserAvatar(String? photoUrl) {
    const double size = 40;
    final effectivePhoto = (photoUrl ?? '').trim().isNotEmpty
        ? photoUrl!.trim()
        : (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 2),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFE6D009), Color(0xFFFBA544)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : Colors.white38,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
                const SizedBox(width: 10),
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
