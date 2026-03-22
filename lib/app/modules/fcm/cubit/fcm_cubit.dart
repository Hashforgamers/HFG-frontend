import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'fcm_state.dart';

class FcmCubit extends Cubit<FcmState> {
  FcmCubit() : super(FcmInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  final SharedPreferences _prefs = locator<SharedPreferences>();
  Future<bool>? _registerRequest;
  static const String _registeredTokenKey = 'fcm_registered_token';
  static const String _registeredUserIdKey = 'fcm_registered_user_id';

  Future<bool> registerFCMToken({bool forceRefresh = false}) {
    final inFlight = _registerRequest;
    if (inFlight != null) return inFlight;

    final request = _registerToken(forceRefresh: forceRefresh);
    _registerRequest = request;
    return request.whenComplete(() {
      if (identical(_registerRequest, request)) {
        _registerRequest = null;
      }
    });
  }

  Future<bool> _registerToken({required bool forceRefresh}) async {
    emit(FcmTokenLoading());
    try {
      final token = await FirebaseMessaging.instance.getToken() ?? '';
      if (token.trim().isEmpty) {
        emit(const FcmTokenError(message: 'FCM token unavailable'));
        return false;
      }

      final userData = await remoteRepo.getUserFromPreferences();
      if (userData == null) {
        emit(const FcmTokenError(message: 'User data unavailable'));
        return false;
      }

      final userId = (userData['id'] ?? userData['user_id'] ?? 0).toString();
      final cachedToken = _prefs.getString(_registeredTokenKey) ?? '';
      final cachedUserId = _prefs.getString(_registeredUserIdKey) ?? '';
      final alreadyRegistered =
          !forceRefresh && cachedToken == token && cachedUserId == userId;

      if (alreadyRegistered) {
        emit(FcmTokenRegistered());
        return true;
      }

      final response = await remoteRepo.registerFCMToken(
        userId: userId,
        token: token,
      );
      if (response == 'FCM token registered') {
        await _prefs.setString(_registeredTokenKey, token);
        await _prefs.setString(_registeredUserIdKey, userId);
        emit(FcmTokenRegistered());
        return true;
      }

      emit(FcmTokenError(message: response));
      return false;
    } catch (e) {
      emit(FcmTokenError(message: e.toString()));
      return false;
    }
  }
}
