import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournaments_register_cubit.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_team_members_view.dart';

class TournamentsTeamLookupView extends StatefulWidget {
  const TournamentsTeamLookupView({super.key, required this.eventId});

  final String eventId;

  @override
  State<TournamentsTeamLookupView> createState() =>
      _TournamentsTeamLookupViewState();
}

class _TournamentsTeamLookupViewState extends State<TournamentsTeamLookupView> {
  final TextEditingController _teamIdController = TextEditingController();
  late final TournamentsRegisterCubit _cubit;
  late Future<List<Map<String, dynamic>>> _myTeamsFuture;

  @override
  void initState() {
    super.initState();
    _cubit = TournamentsRegisterCubit();
    _myTeamsFuture = _cubit.fetchMyTeamsForEvent(widget.eventId);
  }

  @override
  void dispose() {
    _cubit.close();
    _teamIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'View Team',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff291702), Color(0xff000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _myTeamsFuture,
                builder: (context, snapshot) {
                  final teams = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (teams.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Teams',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...teams.map((team) {
                        final teamId = (team['team_id'] ?? '').toString();
                        final teamName =
                            (team['team_name'] ?? 'Team').toString();
                        final members = (team['member_count'] ?? 0).toString();
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(
                            teamName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Team ID: $teamId • Members: $members',
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white54,
                            size: 14,
                          ),
                          onTap: () {
                            Get.to(
                              () => TournamentsTeamMembersView(
                                eventId: widget.eventId,
                                teamId: teamId,
                                teamName: teamName,
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              Text(
                'Find Team Members',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a team ID for this event and open the members list.',
                style: GoogleFonts.inter(
                  color: const Color(0xFFC9C9C9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team ID',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildViewButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xff6A6969), Color(0xff323232)],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _teamIdController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ex: 123',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff00DC00)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: () {
          final teamId = _teamIdController.text.trim();
          if (teamId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Team ID is required'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          Get.to(
            () => TournamentsTeamMembersView(
              eventId: widget.eventId,
              teamId: teamId,
              teamName: 'Team $teamId',
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          'View Team Members',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
