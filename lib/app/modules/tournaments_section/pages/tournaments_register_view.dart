import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import '../cubit/tournaments_register_cubit.dart';

class TournamentsRegisterView extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentsRegisterView({super.key, required this.tournament});

  @override
  State<TournamentsRegisterView> createState() =>
      _TournamentsRegisterViewState();
}

class _TournamentsRegisterViewState extends State<TournamentsRegisterView> {
  late final TournamentsRegisterCubit _cubit;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController teamNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentsRegisterCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    nameController.dispose();
    teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;

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
                    "Team '${state.data['team']}' has been registered.",
                  ),
                  backgroundColor: const Color(0xff00DC00),
                ),
              );
              Get.back(); // optional navigation back
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
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                          "Register Now",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "(You will be the leader by default)",
                          style: GoogleFonts.inter(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel("Your Name"),
                        const SizedBox(height: 10),
                        GradientTextField(controller: nameController),

                        const SizedBox(height: 12),
                        _buildLabel("Team Name"),
                        const SizedBox(height: 10),
                        GradientTextField(controller: teamNameController),

                        const SizedBox(height: 30),
                        _buildRegisterButton(state),
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

  Widget _buildHeaderBanner(String? bannerPath) {
    final imagePath =
        (bannerPath ?? 'assets/hash_store_images/tournament_banner.png').trim();
    final isNetwork = imagePath.startsWith('http');
    return Stack(
      children: [
        ClipRRect(
          child: (isNetwork
              ? Image.network(
                  imagePath,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  imagePath,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
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
      fontSize: 15,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildRegisterButton(TournamentsRegisterState state) {
    final isLoading = state is TournamentsRegisterLoading;

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
                _submitCreateTeam(context);
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
                '+ Create your Team',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  void _submitCreateTeam(BuildContext context) {
    final leaderName = nameController.text.trim();
    final teamName = teamNameController.text.trim();

    if (leaderName.isEmpty) {
      _showValidationError(context, 'Leader name is required.');
      return;
    }
    if (leaderName.length < 3) {
      _showValidationError(
        context,
        'Leader name must be at least 3 characters.',
      );
      return;
    }
    if (teamName.isEmpty) {
      _showValidationError(context, 'Team name is required.');
      return;
    }
    if (teamName.length < 3) {
      _showValidationError(context, 'Team name must be at least 3 characters.');
      return;
    }

    _cubit.registerTeam(
      eventId: widget.tournament.id,
      leaderName: leaderName,
      teamName: teamName,
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

class GradientTextField extends StatelessWidget {
  final String? hint;
  final TextEditingController controller;

  const GradientTextField({super.key, this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xff6A6969), Color(0xff323232)],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(19),
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
}
