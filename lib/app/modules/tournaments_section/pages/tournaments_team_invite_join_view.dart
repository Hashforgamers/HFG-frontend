import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_team_members_cubit.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournaments_register_cubit.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';

class TournamentsTeamInviteJoinView extends StatefulWidget {
  const TournamentsTeamInviteJoinView({
    super.key,
    required this.eventId,
    required this.teamId,
  });

  final String eventId;
  final String teamId;

  @override
  State<TournamentsTeamInviteJoinView> createState() =>
      _TournamentsTeamInviteJoinViewState();
}

class _TournamentsTeamInviteJoinViewState
    extends State<TournamentsTeamInviteJoinView> {
  final TournamentsRegisterCubit _registerCubit = TournamentsRegisterCubit();
  final TournamentTeamMembersCubit _membersCubit = TournamentTeamMembersCubit();

  bool _joining = true;
  bool _joined = false;
  String _error = '';
  List<Map<String, dynamic>> _members = const [];
  String _teamName = 'Team';

  @override
  void initState() {
    super.initState();
    _joinAndLoad();
  }

  @override
  void dispose() {
    _registerCubit.close();
    _membersCubit.close();
    super.dispose();
  }

  Future<void> _joinAndLoad() async {
    try {
      await _registerCubit.joinTeam(
        eventId: widget.eventId,
        teamId: widget.teamId,
      );
      final members = await _membersCubit.remoteRepo.fetchEventTeamMembers(
        eventId: widget.eventId,
        teamId: widget.teamId,
      );
      if (!mounted) return;
      setState(() {
        _joined = true;
        _members = members;
        if (members.isNotEmpty) {
          final first = members.first;
          _teamName =
              (first['team_name'] ?? first['name'] ?? _teamName).toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff291702), Color(0xff000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _joining
                ? const Center(child: TournamentsLoader.screen())
                : _joined
                ? _buildSuccess()
                : _buildFailure(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xff00DC00), size: 86),
        const SizedBox(height: 14),
        Text(
          'Joined Team Successfully',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _teamName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Team ID: ${widget.teamId}',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                'Members: ${_members.length}',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff00DC00),
              foregroundColor: Colors.black,
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailure() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 72),
        const SizedBox(height: 12),
        Text(
          'Unable to join team',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error.isEmpty ? 'Please try again.' : _error,
          style: GoogleFonts.inter(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _joinAndLoad,
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

