import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournament_registration_result_pages.dart';
import 'package:hash/app/modules/tournaments_section/services/tournament_payment_service.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournament_finalizing_registration_dialog.dart';
import '../cubit/tournaments_register_cubit.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

class TournamentsRegisterView extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentsRegisterView({super.key, required this.tournament});

  @override
  State<TournamentsRegisterView> createState() =>
      _TournamentsRegisterViewState();
}

class _TournamentsRegisterViewState extends State<TournamentsRegisterView> {
  late final TournamentsRegisterCubit _cubit;
  final TournamentPaymentService _paymentService = TournamentPaymentService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController teamNameController = TextEditingController();
  bool _isPaymentProcessing = false;
  bool _isBlockingLoaderVisible = false;

  @override
  void initState() {
    super.initState();
    _cubit = TournamentsRegisterCubit();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final isCommunitySolo =
        t.source == 'community' && t.teamMode.toLowerCase() == 'solo';

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<TournamentsRegisterCubit, TournamentsRegisterState>(
          listener: (context, state) {
            if (state is TournamentsRegisterLoading) {
              _showBlockingLoader();
            } else if (state is TournamentsRegisterSuccess) {
              _hideBlockingLoader();
              if (!mounted) return;
              Get.to(
                () => TournamentRegistrationSuccessPage(
                  tournamentTitle: widget.tournament.title,
                ),
              );
            } else if (state is TournamentsRegisterSettlementPending) {
              _hideBlockingLoader();
              if (!mounted) return;
              Get.to(
                () => TournamentPaymentProcessingPage(
                  tournamentTitle: widget.tournament.title,
                  message: state.message,
                ),
              );
            } else if (state is TournamentsRegisterError) {
              _hideBlockingLoader();
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
                          isCommunitySolo
                              ? 'Registering as an individual player'
                              : '(You will be the leader by default)',
                          style: GoogleFonts.inter(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!isCommunitySolo) ...[
                          _buildLabel("Your Name"),
                          const SizedBox(height: 10),
                          GradientTextField(controller: nameController),
                          const SizedBox(height: 12),
                          _buildLabel("Team Name"),
                          const SizedBox(height: 10),
                          GradientTextField(controller: teamNameController),
                        ],

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
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
    final isLoading =
        state is TournamentsRegisterLoading || _isPaymentProcessing;
    final isCommunitySolo =
        widget.tournament.source == 'community' &&
        widget.tournament.teamMode.toLowerCase() == 'solo';

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
                isCommunitySolo ? 'Register Now' : '+ Create your Team',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _submitCreateTeam(BuildContext context) async {
    final leaderName = nameController.text.trim();
    final teamName = teamNameController.text.trim();
    final isCommunitySolo =
        widget.tournament.source == 'community' &&
        widget.tournament.teamMode.toLowerCase() == 'solo';

    if (!isCommunitySolo && leaderName.isEmpty) {
      _showValidationError('Leader name is required.');
      return;
    }
    if (!isCommunitySolo && leaderName.length < 3) {
      _showValidationError('Leader name must be at least 3 characters.');
      return;
    }
    if (!isCommunitySolo && teamName.isEmpty) {
      _showValidationError('Team name is required.');
      return;
    }
    if (!isCommunitySolo && teamName.length < 3) {
      _showValidationError('Team name must be at least 3 characters.');
      return;
    }

    final analytics = locator<AnalyticsService>();
    final params = _analyticsParameters();
    await analytics.log('tournament_join_started', parameters: params);
    if (!context.mounted) return;

    setState(() => _isPaymentProcessing = true);
    TournamentPaymentResult? payment;
    try {
      if (_entryFeeAmount() > 0) {
        await analytics.log('payment_started', parameters: params);
        if (!context.mounted) return;
      }
      payment = await _paymentService.payRegistrationFee(
        context: context,
        tournament: widget.tournament,
      );
      if (!mounted) return;
      if (payment == null) {
        await analytics.log(
          'payment_failed',
          parameters: {...params, 'failure_reason': 'user_cancelled'},
        );
        _openPaymentFailedPage('Payment was not completed.');
        return;
      }
    } catch (e) {
      await analytics.log(
        'payment_failed',
        parameters: {
          ...params,
          'failure_reason': AnalyticsService.normalizeFailureReason(e),
        },
      );
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      _openPaymentFailedPage(
        message.trim().isEmpty
            ? 'Unable to start payment. Please try again.'
            : message,
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }

    _cubit.registerTeam(
      eventId: widget.tournament.id,
      leaderName: leaderName,
      teamName: teamName,
      source: widget.tournament.source,
      teamMode: widget.tournament.teamMode,
      payment: payment,
    );
  }

  double _entryFeeAmount() =>
      double.tryParse(
        widget.tournament.entryFee.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ??
      0;

  Map<String, Object?> _analyticsParameters() {
    final tournament = widget.tournament;
    final playerParts = tournament.players.split('/');
    final participants = int.tryParse(playerParts.first.trim());
    final capacity = playerParts.length > 1
        ? int.tryParse(playerParts.last.trim())
        : null;
    return {
      'tournament_id': tournament.id,
      'game_id': tournament.game,
      'game_name': tournament.game,
      'tournament_mode': tournament.teamMode,
      'entry_fee': _entryFeeAmount(),
      'host_id': tournament.hostUserId,
      'team_status': tournament.teamMode.toLowerCase() == 'solo'
          ? 'solo'
          : 'creating',
      'participant_count': participants,
      'slots_remaining': participants == null || capacity == null
          ? null
          : (capacity - participants).clamp(0, capacity),
      'source_screen': 'tournament_registration',
    };
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showBlockingLoader() {
    if (!mounted || _isBlockingLoaderVisible) return;
    _isBlockingLoaderVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .82),
      builder: (_) => TournamentFinalizingRegistrationDialog(
        tournamentTitle: widget.tournament.title,
      ),
    );
  }

  void _hideBlockingLoader() {
    if (!mounted || !_isBlockingLoaderVisible) return;
    _isBlockingLoaderVisible = false;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _openPaymentFailedPage(String message) async {
    final retry = await Get.to<bool>(
      () => TournamentPaymentFailedPage(message: message),
    );
    if (retry == true && mounted) {
      await _submitCreateTeam(context);
    }
  }

  @override
  void dispose() {
    _hideBlockingLoader();
    _cubit.close();
    nameController.dispose();
    teamNameController.dispose();
    super.dispose();
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
