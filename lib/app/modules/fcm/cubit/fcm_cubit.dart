import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'fcm_state.dart';

class FcmCubit extends Cubit<FcmState> {
  FcmCubit() : super(FcmInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> registerFCMToken() async {
    emit(FcmTokenLoading());
    try {
      String token = await FirebaseMessaging.instance.getToken() ?? '';
      final userData = await remoteRepo.getUserFromPreferences();
      if (userData != null) {
        final userId = userData['id'] ?? 0;
        final response = await remoteRepo.registerFCMToken(
          userId: userId.toString(),
          token: token,
        );
        if (response == 'FCM token registered') {
          emit(FcmTokenRegistered());
        } else {
          emit(FcmTokenError(message: response));
        }
      }
    } catch (e, st) {
      emit(FcmTokenError(message: e.toString()));
    }
  }
}
