import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'tournament_home_state.dart';

class TournamentHomeCubit extends Cubit<TournamentHomeState> {
  TournamentHomeCubit() : super(TournamentHomeInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  List<TournamentModel> _allTournaments = [];

  Future<void> fetchTournaments() async {
    emit(TournamentHomeLoading());
    try {
      final events = await remoteRepo.fetchPublicEvents();
      final tournaments = events.map(TournamentModel.fromJson).toList();

      _allTournaments = tournaments;
      emit(TournamentHomeLoaded(tournaments: tournaments));
    } catch (e) {
      emit(TournamentHomeError(message: e.toString()));
    }
  }

  void filterTournaments(String category) {
    if (state is! TournamentHomeLoaded) return;

    if (category == 'All') {
      emit(TournamentHomeLoaded(tournaments: _allTournaments));
      return;
    }

    final filtered = _allTournaments
        .where((t) => t.matchesFilter(category))
        .toList();

    emit(TournamentHomeLoaded(tournaments: filtered));
  }
}
