import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournaments_register_cubit.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';

class TournamentsJoinTeamView extends StatefulWidget {
  const TournamentsJoinTeamView({super.key, required this.tournament});

  final TournamentModel tournament;

  @override
  State<TournamentsJoinTeamView> createState() =>
      _TournamentsJoinTeamViewState();
}

class _TournamentsJoinTeamViewState extends State<TournamentsJoinTeamView> {
  late final TournamentsRegisterCubit _cubit;
  final TextEditingController _teamIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentsRegisterCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    _teamIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<TournamentsRegisterCubit, TournamentsRegisterState>(
          listener: (context, state) {
            if (state is TournamentsRegisterSuccess) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "You've joined team ${state.data['team_id'] ?? ''}.",
                  ),
                  backgroundColor: const Color(0xff00DC00),
                ),
              );
              Get.back();
            } else if (state is TournamentsRegisterError) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is TournamentsRegisterLoading;
            final t = widget.tournament;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(
                    t.banner.isNotEmpty ? t.banner : t.imageUrl,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Team',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the Team ID shared by your leader.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC9C9C9),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              _buildLabel('Team ID'),
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _teamIdController,
                                hint: 'Ex: 123',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildJoinButton(isLoading),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(String imagePath) {
    return Stack(
      children: [
        ClipRRect(
          child: Image.asset(
            imagePath,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Get.back(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
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
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton(bool isLoading) {
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
        onPressed: isLoading
            ? null
            : () {
                _submitJoinTeam(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: isLoading
            ? const TournamentsLoader.button()
            : Text(
                'Join Team',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  void _submitJoinTeam(BuildContext context) {
    final teamId = _teamIdController.text.trim();
    if (teamId.isEmpty) {
      _showValidationError(context, 'Team ID is required.');
      return;
    }
    if (teamId.length < 2) {
      _showValidationError(context, 'Team ID looks invalid.');
      return;
    }
    _cubit.joinTeam(eventId: widget.tournament.id, teamId: teamId);
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}
