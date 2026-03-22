import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'hash_coin_state.dart';

class HashCoinCubit extends Cubit<HashCoinState> {
  HashCoinCubit() : super(HashCoinInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  Future<void>? _inFlightRequest;

  Future<void> getHashCoin({bool forceRefresh = true}) {
    if (!forceRefresh && state is HashCoinLoaded) {
      return Future.value();
    }

    final inFlight = _inFlightRequest;
    if (inFlight != null) return inFlight;

    final request = _loadHashCoin(forceRefresh: forceRefresh);
    _inFlightRequest = request;
    return request.whenComplete(() {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    });
  }

  Future<void> _loadHashCoin({required bool forceRefresh}) async {
    if (forceRefresh || state is! HashCoinLoaded) {
      emit(HashCoinLoading());
    }

    try {
      final response = await remoteRepo.getHashCoin();
      emit(HashCoinLoaded(hashCoin: response));
    } catch (e) {
      if (state is! HashCoinLoaded) {
        emit(HashCoinError(message: e.toString()));
      }
    }
  }
}
