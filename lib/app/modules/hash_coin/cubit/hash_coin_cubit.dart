import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'hash_coin_state.dart';

class HashCoinCubit extends Cubit<HashCoinState> {
  HashCoinCubit() : super(HashCoinInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getHashCoin() async {
    emit(HashCoinLoading());

    final userData = await remoteRepo.getUserFromPreferences();
    if (userData != null) {
      final userId = userData['id'] ?? 0;
      final response = await remoteRepo.getHashCoin(userId: userId.toString());
      emit(HashCoinLoaded(hashCoin: response));
    } else {
      emit(const HashCoinError(message: 'User data not found'));
    }
  }
}
