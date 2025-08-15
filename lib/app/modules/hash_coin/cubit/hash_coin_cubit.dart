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
    try {
      final response = await remoteRepo.getHashCoin();
      emit(HashCoinLoaded(hashCoin: response));
    } catch (e) {
      emit(HashCoinError(message: e.toString()));
    }
  }
}
