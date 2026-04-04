import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'hash_coin_state.dart';

class HashCoinCubit extends Cubit<HashCoinState> {
  HashCoinCubit() : super(HashCoinInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  Future<void>? _inFlightRequest;
  String _loadedUserId = '';

  String _currentBackendUserId() {
    if (!Get.isRegistered<UserController>()) return '';
    return Get.find<UserController>().userId.trim();
  }

  Future<void> getHashCoin({bool forceRefresh = true}) {
    final currentUserId = _currentBackendUserId();
    if (currentUserId.isEmpty) {
      reset();
      return Future.value();
    }

    final userChanged =
        _loadedUserId.isNotEmpty && _loadedUserId != currentUserId;
    if (userChanged) {
      reset();
      forceRefresh = true;
    }

    if (!forceRefresh &&
        state is HashCoinLoaded &&
        _loadedUserId == currentUserId) {
      return Future.value();
    }

    final inFlight = _inFlightRequest;
    if (inFlight != null) return inFlight;

    final request = _loadHashCoin(
      forceRefresh: forceRefresh,
      requestUserId: currentUserId,
    );
    _inFlightRequest = request;
    return request.whenComplete(() {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    });
  }

  Future<void> _loadHashCoin({
    required bool forceRefresh,
    required String requestUserId,
  }) async {
    if (forceRefresh ||
        state is! HashCoinLoaded ||
        _loadedUserId != requestUserId) {
      emit(HashCoinLoading());
    }

    try {
      final response = await remoteRepo.getHashCoin();
      if (_currentBackendUserId() != requestUserId) {
        return;
      }
      _loadedUserId = requestUserId;
      emit(HashCoinLoaded(hashCoin: response));
    } catch (e) {
      if (_currentBackendUserId() != requestUserId) {
        return;
      }
      if (state is! HashCoinLoaded) {
        emit(HashCoinError(message: e.toString()));
      }
    }
  }

  void reset() {
    _loadedUserId = '';
    _inFlightRequest = null;
    if (state is! HashCoinInitial) {
      emit(HashCoinInitial());
    }
  }
}
