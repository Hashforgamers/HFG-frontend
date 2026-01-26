import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_details_view.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_leaderboard_view.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_app_bar.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:intl/intl.dart';

import '../../../data/services/user_controller.dart';
import '../cubit/tournament_home_cubit.dart';

class TournamentsHomeView extends StatefulWidget {
  const TournamentsHomeView({super.key});

  @override
  State<TournamentsHomeView> createState() => _TournamentsHomeViewState();
}

class _TournamentsHomeViewState extends State<TournamentsHomeView> {

  late final TournamentHomeCubit _cubit;

  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentHomeCubit();
    _cubit.fetchTournaments();
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
        body: CustomScrollView(
          slivers: [
            const TournamentsAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: BlocBuilder<TournamentHomeCubit, TournamentHomeState>(
                  builder: (context, state) {
                    if (state is TournamentHomeLoading) {
                      return const Center(child: RainbowLoadingBar());
                    } else if (state is TournamentHomeLoaded) {
                      return _buildBodyContent(state.tournaments);
                    } else if (state is TournamentHomeError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(List<Map<String, dynamic>> tournaments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Tournaments",
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
        _buildTournamentList(tournaments),
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
        const SizedBox(height: 16),
        _buildLeaderboardButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTournamentList(List<Map<String, dynamic>> tournaments) {
    if (tournaments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'No tournaments found',
          style: TextStyle(color: Colors.white70),
        ),
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

  Widget _buildTournamentCard(Map<String, dynamic> t) {
    final dateFormat = DateFormat('d MMM');
    final start = t['startDate'] as DateTime;
    final end = t['endDate'] as DateTime;
    final dateRange = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    final String imagePath = t['imageUrl'] as String;

    return GestureDetector(
      onTap: () {
        Get.to(() => TournamentsDetailsView(tournament: t));
      },
      child: Column(
        children: [
          Container(
            width: 150,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['title'] as String,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              Row(children: const [
                Icon(Icons.person, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('You', style: TextStyle(color: Colors.white)),
              ]),
              Row(
                children: const [
                  Icon(Icons.star, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('100 Points', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.emoji_events, color: Colors.green, size: 16),
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

  Widget _buildLeaderboardButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            // TODO: Navigate to Leaderboard
            Get.to(TournamentsLeaderboardView());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'View Leaderboard',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.north_east, color: Colors.white, size: 25),
            ],
          ),
        ),
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
          errorListener: (error) => print('Avatar image error: $error'),
        )
            : const NetworkImage(
          'https://wallpapers.com/images/hd/placeholder-profile-icon-20tehfawxt5eihco.jpg',
        ) as ImageProvider,
        backgroundColor: Colors.white,
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
  const _TabsSection({super.key});

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
                    context
                        .read<TournamentHomeCubit>()
                        .filterTournaments(text);
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