import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'game_pass_state.dart';

class GamePassCubit extends Cubit<GamePassState> {
  GamePassCubit() : super(GamePassInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getGamePass() async {
    emit(GamePassLoading());

    final userData = await remoteRepo.getUserFromPreferences();
    if (userData != null) {
      final userId = userData['id'] ?? 0;
      final response = await remoteRepo.getGamePass(userId: userId.toString());
      if (response.isNotEmpty) {
        emit(GamePassLoaded(gamePass: response));
      } else {
        emit(GamePassError(message: 'No game pass found'));
      }
    }
  }
}
