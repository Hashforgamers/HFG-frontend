import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_register_view.dart';
import 'package:hash/app/modules/tournaments_section/widgets/glassy_border_container.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_app_bar.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:intl/intl.dart';

import '../../../data/services/user_controller.dart';
import '../cubit/tournaments_details_cubit.dart';

class TournamentsDetailsView extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentsDetailsView({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentsDetailsView> createState() => _TournamentsDetailsViewState();
}

class _TournamentsDetailsViewState extends State<TournamentsDetailsView> {
  late final TournamentsDetailsCubit _cubit;
  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentsDetailsCubit(widget.tournament);
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
        backgroundColor: Colors.black,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<TournamentsDetailsCubit, TournamentsDetailsState>(
                builder: (context, state) {
                  if (state is TournamentsDetailsLoaded) {
                    return _buildBodyContent(state.tournament);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(Map<String, dynamic> t) {
    final dateFormat = DateFormat('d MMM');
    final start = t['startDate'] as DateTime?;
    final end = t['endDate'] as DateTime?;
    final dateRange = start != null && end != null
        ? '${dateFormat.format(start)} - ${dateFormat.format(end)}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBanner(t['banner'] ?? t['imageUrl']),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                t['title'] ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              // Entry Fee + Status + Time Left
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Rs. ${t['entryFee'] ?? '0'}",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // STATUS BADGE – ALWAYS GREEN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFF6DFB60), width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (t['status'] as String?)?.toLowerCase() ?? '',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6DFB60),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  if (t['timeLeft'] != null && t['timeLeft'].toString().isNotEmpty)
                    Text(
                      "Starts in ${t['timeLeft']}",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),

              // if (dateRange.isNotEmpty) ...[
              //   const SizedBox(height: 4),
              //   Text(
              //     dateRange,
              //     style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              //   ),
              // ],

              const SizedBox(height: 25),

              // Stats Row
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0x0fffffff),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(t['prizePool']?.toString() ?? '-', 'assets/hash_store_images/points.png'),
                    _buildStatItem(t['players']?.toString() ?? '-', 'assets/hash_store_images/points.png'),
                    _buildStatItem(t['teamMode']?.toString() ?? '-', 'assets/hash_store_images/points.png'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Tabs
              _buildTabs(),
              const SizedBox(height: 20),
              _buildTabContent(t),

              const SizedBox(height: 25),

              //Register Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFC06701)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(TournamentsRegisterView(tournament: widget.tournament));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Register Now',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              // const SizedBox(height: 40),

              // Your Position (Footer)
              // _buildFooterPlayerInfo(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHeaderBanner(String? bannerPath) {
    return Stack(
      children: [
        ClipRRect(
          child: Image.asset(
            bannerPath ?? 'assets/hash_store_images/tournament_banner.png',
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 18),
              onPressed: () {
                //TODO: Share Operation
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String assetPath) {
    return Column(
      children: [
        Image.asset(
          assetPath,
          height: 50,
          width: 50,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int selectedTabIndex = 0; // Add this in your _TournamentsDetailsViewState class

  Widget _buildTabs() {
    final List<String> tabs = ["Overview", "Teams", "Rules", "Technical"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Stack(
        children: [
          // Base divider line (always visible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: Colors.white12, // subtle divider color
            ),
          ),

          // Tabs row with gradient underline on selected one
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(tabs.length, (index) {
              final isActive = selectedTabIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = index;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.inter(
                            color: isActive
                                ? Colors.white
                                : Colors.white54,
                            fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Gradient underline
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? const LinearGradient(
                            colors: [
                              Color(0xFFFBA544),
                              Color(0xFF6DFB60),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                              : const LinearGradient(
                            colors: [Colors.transparent, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> t) {
    switch (selectedTabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t['description'] ?? 'No description available.',
              textAlign: TextAlign.start,
              style: GoogleFonts.inter(
                color: const Color(0xFFC9C9C9),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            SizedBox(height: 15),
            Text(
              "Hosted by ${t['hostedBy'] ?? 'Hash'}",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
          ],
        );
      case 1:
        final teams = t['teams'] as List<dynamic>? ?? [];

        return Column(
          children: [
            // LIMITED HEIGHT LIST (shows ~3 items)
            Container(
              height: 200, // adjust to match exact Figma height if needed
              child: Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.only(bottom: 60),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildGlassContainer(teams[index]),
                      );
                    },
                  ),

                  // EXPAND BUTTON (bottom-right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpandedTeamListView(teams: teams),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset("assets/hash_store_images/expand_icon.png", height: 32, width: 32,),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return Text(
          'Rules:\n${t['rules'] ?? 'No rules provided.'}',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        );
      case 3:
        return Text(
          'Technical Details:\n${t['technical'] ?? 'No technical info provided.'}',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        );
      default:
        return const SizedBox.shrink();
    }
  }


  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8A241), Color(0xFFC06701)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Register action
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Register Now',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.north_east, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterPlayerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildOptimizedUserAvatar(userController.user.value.photoUrl),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('You', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Registered Player', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 28),
        ],
      ),
    );
  }

  Widget _buildOptimizedUserAvatar(String? photoUrl) {
    const double size = 40;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImageProvider(
          photoUrl,
          errorListener: (error) => print('Avatar error: $error'),
        )
            : const AssetImage(
          'assets/hash_store_images/tournament_banner.png',
        ) as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGlassContainer(Map<String, dynamic> team) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white12, Colors.white24, Colors.white30.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5, color: Colors.white30),
          ),
          child: Row(
            children: [
              Text(
                team['rank'] ?? '-',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (team['photoUrl'] != null && team['photoUrl'].isNotEmpty)
                      ? AssetImage(team['photoUrl'])
                      : const AssetImage('assets/hash_store_images/team_fallback.png')
                  as ImageProvider,
                ),
              ),
              SizedBox(width: 15),
              Text(
                team['name'] ?? 'Unknown',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green, size: 10),
                      SizedBox(width: 5),
                      Text("${team['points'] ?? '0'} Points", style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                  Text(
                    "${team['matchesWon'] ?? '0'} Matches Won",
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class ExpandedTeamListView extends StatelessWidget {
  final List<dynamic> teams;

  const ExpandedTeamListView({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white,),
        ),
        title: Text('Teams', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),

      body: Stack(
        children: [
          // THE TEAM LIST
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildExpandedTeamGlassContainer(context, teams[index]),
              );
            },
          ),

          // SHRINK BUTTON (bottom-right)
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  "assets/hash_store_images/shrink_icon.png",
                  height: 32,
                  width: 32,
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFC06701)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "+ Create your Team",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedTeamGlassContainer(BuildContext context, Map<String, dynamic> team) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white12,
                Colors.white24,
                Colors.white30.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(width: 0.6, color: Colors.white24),
          ),
          child: Row(
            children: [
              // Rank
              Text(
                team['rank'] ?? '-',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14),

              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: (team['photoUrl'] != null && team['photoUrl'].isNotEmpty)
                      ? AssetImage(team['photoUrl'])
                      : const AssetImage('assets/hash_store_images/team_fallback.png')
                  as ImageProvider,
                ),
              ),

              SizedBox(width: 16),

              // Name + Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team['name'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green, size: 11),
                      SizedBox(width: 2),
                      Text(
                        "${team['points']} Points",
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "${team['matchesWon']} Matches Won",
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

}
