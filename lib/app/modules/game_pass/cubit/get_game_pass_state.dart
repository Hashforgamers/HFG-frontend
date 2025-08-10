part of 'get_game_pass_cubit.dart';

abstract class GetGamePassState extends Equatable {
  const GetGamePassState();
}

class GetGamePassInitial extends GetGamePassState {
  @override
  List<Object?> get props => [];
}

class GetGamePassLoading extends GetGamePassState {
  @override
  List<Object?> get props => [];
}

class GetGamePassLoaded extends GetGamePassState {
  final List<GetPassModel> gamePass;
  const GetGamePassLoaded({required this.gamePass});
  @override
  List<Object?> get props => [gamePass];
}

class GetGamePassError extends GetGamePassState {
  final String message;
  const GetGamePassError({required this.message});
  @override
  List<Object?> get props => [message];
}
