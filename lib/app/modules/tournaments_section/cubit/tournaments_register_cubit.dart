import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tournaments_register_state.dart';

class TournamentsRegisterCubit extends Cubit<TournamentsRegisterState> {
  TournamentsRegisterCubit() : super(TournamentsRegisterInitial()) {
    print('🟩 TournamentsRegisterCubit created');
  }

  Future<void> registerTeam({
    required String leaderName,
    required String teamName,
    required List<String> players,
  }) async {
    emit(TournamentsRegisterLoading());
    try {
      // Simulate API call (you’ll later replace this with a real backend call)
      await Future.delayed(const Duration(seconds: 2));

      // Example result (you can remove this mock when connected to API)
      final result = {
        "team": teamName,
        "leader": leaderName,
        "players": players.where((e) => e.trim().isNotEmpty).toList(),
      };

      emit(TournamentsRegisterSuccess(data: result));
    } catch (e) {
      emit(TournamentsRegisterError(message: e.toString()));
    }
  }
}
