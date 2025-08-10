import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/model/food_menu_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'get_food_menu_state.dart';

class GetFoodMenuCubit extends Cubit<GetFoodMenuState> {
  GetFoodMenuCubit() : super(GetFoodMenuInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> getFoodMenu(String vendorId) async {
    emit(GetFoodMenuLoading());
    try {
      final foodMenu = await remoteRepo.getFoodMenu(vendorId: vendorId);
      emit(GetFoodMenuLoaded(foodMenu: foodMenu.categories));
    } catch (e) {
      emit(GetFoodMenuError(message: e.toString()));
    }
  }
}
