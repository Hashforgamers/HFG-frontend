import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_team_members_cubit.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import 'package:share_plus/share_plus.dart';

class TournamentsTeamMembersView extends StatelessWidget {
  const TournamentsTeamMembersView({
    super.key,
    required this.eventId,
    required this.teamId,
    required this.teamName,
  });

  final String eventId;
  final String teamId;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TournamentTeamMembersCubit()
            ..fetchTeamMembers(eventId: eventId, teamId: teamId),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Team Members',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () => _shareTeamId(context),
              icon: const Icon(Icons.share),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff291702), Color(0xff000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildTeamHeader(context),
              Expanded(
                child:
                    BlocBuilder<
                      TournamentTeamMembersCubit,
                      TournamentTeamMembersState
                    >(
                      builder: (context, state) {
                        if (state is TournamentTeamMembersLoading) {
                          return const TournamentsLoader.screen();
                        }
                        if (state is TournamentTeamMembersError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (state is TournamentTeamMembersLoaded) {
                          if (state.members.isEmpty) {
                            return const Center(
                              child: Text(
                                'No members found for this team.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.members.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final member = state.members[index];
                              final name =
                                  (member['name'] ??
                                          member['user_name'] ??
                                          member['username'] ??
                                          member['email'] ??
                                          'Member ${index + 1}')
                                      .toString();
                              final role =
                                  (member['role'] ?? member['team_role'] ?? '')
                                      .toString();
                              return _buildMemberCard(
                                index: index,
                                name: name,
                                role: role,
                              );
                            },
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

  Widget _buildTeamHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Team ID: $teamId',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff00DC00)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () => _shareTeamId(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(118, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Share Team ID',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required int index,
    required String name,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: index == 0 ? const Color(0xff00DC00) : Colors.white10,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            role.isEmpty ? (index == 0 ? 'Leader' : 'Member') : role,
            style: GoogleFonts.inter(
              color: const Color(0xff00DC00),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _shareTeamId(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my team "$teamName" on HashForGamers. Team ID: $teamId',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team ID shared'),
        backgroundColor: Color(0xff00DC00),
      ),
    );
  }
}
