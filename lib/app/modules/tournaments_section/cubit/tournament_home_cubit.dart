import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tournament_home_state.dart';

class TournamentHomeCubit extends Cubit<TournamentHomeState> {
  TournamentHomeCubit() : super(TournamentHomeInitial());

  List<Map<String, dynamic>> _allTournaments = [];

  Future<void> fetchTournaments() async {
    emit(TournamentHomeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final tournaments = [
        {
          'id': '1',
          'title': 'Major I Tournament',
          'imageUrl': 'assets/hash_store_images/tournament_img1.png',
          'startDate': DateTime(2025, 5, 17),
          'endDate': DateTime(2025, 5, 19),
          'status': 'completed',
        },
        {
          'id': '2',
          'title': 'Major II Tournament',
          'imageUrl': 'assets/hash_store_images/tournament_img2.png',
          'startDate': DateTime(2025, 5, 17),
          'endDate': DateTime(2025, 5, 19),
          'status': 'live',
        },
        {
          'id': '3',
          'title': 'Valorant Major III Tournament',
          'imageUrl': 'assets/hash_store_images/tournament_img1.png',
          'startDate': DateTime(2025, 5, 17),
          'endDate': DateTime(2025, 5, 19),
          'status': 'live',
          'timeLeft': '4d 3h 16m',
        },
        {
          'id': '4',
          'title': 'NBA Finals Clash',
          'imageUrl': 'assets/hash_store_images/tournament_img2.png',
          'startDate': DateTime(2025, 6, 1),
          'endDate': DateTime(2025, 6, 7),
          'status': 'upcoming',
        },
        {
          'id': '5',
          'title': 'Valorant Major IV Tournament',
          'imageUrl': 'assets/hash_store_images/tournament_img1.png',
          'startDate': DateTime(2025, 6, 1),
          'endDate': DateTime(2025, 6, 7),
          'status': 'upcoming',
        },
      ];

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
        .where((t) => t['status'] == category.toLowerCase())
        .toList();

    emit(TournamentHomeLoaded(tournaments: filtered));
  }
}