part of 'get_food_menu_cubit.dart';

abstract class GetFoodMenuState extends Equatable {
  const GetFoodMenuState();
}

class GetFoodMenuInitial extends GetFoodMenuState {
  @override
  List<Object> get props => [];
}

class GetFoodMenuLoading extends GetFoodMenuState {
  @override
  List<Object> get props => [];
}

class GetFoodMenuLoaded extends GetFoodMenuState {
  final List<FoodMenuModel> foodMenu;
  const GetFoodMenuLoaded({required this.foodMenu});
  @override
  List<Object> get props => [foodMenu];
}

class GetFoodMenuError extends GetFoodMenuState {
  final String message;
  const GetFoodMenuError({required this.message});
  @override
  List<Object> get props => [message];
}
