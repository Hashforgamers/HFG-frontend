import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'get_game_pass_state.dart';

class GetGamePassCubit extends Cubit<GetGamePassState> {
  GetGamePassCubit() : super(GetGamePassInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getGamePass() async {
    emit(GetGamePassLoading());
    final userData = await remoteRepo.getUserFromPreferences();
    if (userData != null) {
      final userId = userData['id'] ?? 0;
      final response = await remoteRepo.getUserActiveGamePass(userId: userId);
      if (response.isNotEmpty) {
        emit(GetGamePassLoaded(gamePass: response));
      } else {
        emit(GetGamePassError(message: 'No game pass found'));
      }
    } else {
      emit(GetGamePassError(message: 'User not found'));
    }
  }
}
