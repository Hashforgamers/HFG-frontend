import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'fcm_state.dart';

class FcmCubit extends Cubit<FcmState> {
  FcmCubit() : super(FcmInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  final UserController userController = Get.find();

  Future<void> registerFCMToken() async {
    String token = await FirebaseMessaging.instance.getToken() ?? '';
    String userId = userController.id.value;
    emit(FcmTokenLoading());
    try {
      await remoteRepo.registerFCMToken(userId: userId, token: token);
      emit(FcmTokenRegistered());
    } catch (e) {
      emit(FcmTokenError());
    }
  }
}
