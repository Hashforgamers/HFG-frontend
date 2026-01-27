import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/user_pass/model/user_gaming_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'get_user_gaming_pass_state.dart';

class GetUserGamingPassCubit extends Cubit<GetUserGamingPassState> {
  GetUserGamingPassCubit() : super(GetUserGamingPassInitial());

  final apiClient = locator<RemoteRepoInterface>();

  Future<void> fetchUserGamingPasses(String? vendorId) async {
    emit(GetUserGamingPassLoading());
    try {
      final userGamingPasses = await apiClient.getUserActiveGamePasses(vendorId);
      emit(GetUserGamingPassLoaded(userGamingPasses: userGamingPasses));
    } catch (e) {
      emit(GetUserGamingPassError(message: e.toString()));
    }
  }
}
