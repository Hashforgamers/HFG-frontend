part of 'game_pass_cubit.dart';

abstract class GamePassState extends Equatable {
  const GamePassState();
}

class GamePassInitial extends GamePassState {
  @override
  List<Object?> get props => [];
}

class GamePassLoading extends GamePassState {
  @override
  List<Object?> get props => [];
}

class GamePassLoaded extends GamePassState {
  final List<GetPassModel> gamePass;
  const GamePassLoaded({required this.gamePass});
  @override
  List<Object?> get props => [gamePass];
}

class GamePassError extends GamePassState {
  final String message;
  const GamePassError({required this.message});
  @override
  List<Object?> get props => [message];
}
