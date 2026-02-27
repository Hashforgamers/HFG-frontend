import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';

part 'tournaments_details_state.dart';

class TournamentsDetailsCubit extends Cubit<TournamentsDetailsState> {
  TournamentsDetailsCubit(this._initialTournament)
    : super(TournamentsDetailsLoaded(tournament: _initialTournament)) {
    fetchTournamentDetails();
  }

  final TournamentModel _initialTournament;
  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchTournamentDetails() async {
    emit(TournamentsDetailsLoading());
    try {
      final details = await remoteRepo.fetchEventById(
        eventId: _initialTournament.id,
      );
      final enrichedTournament = TournamentModel.fromJson({
        ...details,
        'id': _initialTournament.id,
      });
      emit(
        TournamentsDetailsLoaded(
          tournament: _mergeTournament(enrichedTournament),
        ),
      );
    } catch (e) {
      AppLogger.e('Tournament details fetch failed: $e');
      emit(TournamentsDetailsLoaded(tournament: _initialTournament));
    }
  }

  TournamentModel _mergeTournament(TournamentModel incoming) {
    return incoming.copyWith(
      isJoined: _initialTournament.isJoined || incoming.isJoined,
      imageUrl: incoming.imageUrl.isEmpty
          ? _initialTournament.imageUrl
          : incoming.imageUrl,
      banner: incoming.banner.isEmpty
          ? _initialTournament.banner
          : incoming.banner,
      timeLeft: incoming.timeLeft.isEmpty
          ? _initialTournament.timeLeft
          : incoming.timeLeft,
      description: incoming.description.isEmpty
          ? _initialTournament.description
          : incoming.description,
      rules: incoming.rules.isEmpty ? _initialTournament.rules : incoming.rules,
      technical: incoming.technical.isEmpty
          ? _initialTournament.technical
          : incoming.technical,
      teams: incoming.teams.isEmpty ? _initialTournament.teams : incoming.teams,
    );
  }
}
