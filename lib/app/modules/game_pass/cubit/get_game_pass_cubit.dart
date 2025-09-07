import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'get_game_pass_state.dart';

class GetGamePassCubit extends Cubit<GetGamePassState> {
  GetGamePassCubit() : super(GetGamePassInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getActiveGamePass() async {
    emit(GetGamePassLoading());
    try {
      final userData = await remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id']?.toString() ?? '0';
        final response = await remoteRepo.getUserActiveGamePass(userId: userId);
        if (response.isNotEmpty) {
          emit(GetGamePassLoaded(gamePass: response));
        } else {
          emit(GetGamePassError(message: 'No active game pass found'));
        }
      } else {
        emit(GetGamePassError(message: 'User not found'));
      }
    } catch (e) {
      emit(GetGamePassError(message: 'Failed to load game passes: $e'));
    }
  }

  Future<void> getGamePassHistory() async {
    emit(GetGamePassLoading());
    try {
      final userData = await remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id']?.toString() ?? '0';
        print('Fetching game pass history for user: $userId');
        final response = await remoteRepo.getUserActiveGamePass(userId: userId);
        print('Game pass history response: ${response.length} items');
        if (response.isNotEmpty) {
          print('First pass: ${response.first.name} - ${response.first.validFrom} to ${response.first.validTo}');
          emit(GetGamePassLoaded(gamePass: response));
        } else {
          emit(GetGamePassError(message: 'No game pass history found'));
        }
      } else {
        emit(GetGamePassError(message: 'User not found'));
      }
    } catch (e) {
      print('Error in getGamePassHistory: $e');
      emit(GetGamePassError(message: 'Failed to load game pass history: $e'));
    }
  }

  Future<void> getAllGamePasses() async {
    emit(GetGamePassLoading());
    try {
      final userData = await remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id']?.toString() ?? '0';
        final activePasses = await remoteRepo.getUserActiveGamePass(userId: userId);
        final historyPasses = await remoteRepo.getGamePass(userId: userId, type: 'history');
        
        final allPasses = [...activePasses, ...historyPasses];
        if (allPasses.isNotEmpty) {
          emit(GetGamePassLoaded(gamePass: allPasses));
        } else {
          emit(GetGamePassError(message: 'No game passes found'));
        }
      } else {
        emit(GetGamePassError(message: 'User not found'));
      }
    } catch (e) {
      emit(GetGamePassError(message: 'Failed to load game passes: $e'));
    }
  }
}
