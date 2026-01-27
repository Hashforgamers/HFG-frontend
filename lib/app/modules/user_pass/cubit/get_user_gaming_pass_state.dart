part of 'get_user_gaming_pass_cubit.dart';

abstract class GetUserGamingPassState extends Equatable {}

class GetUserGamingPassInitial extends GetUserGamingPassState {
  @override
  List<Object?> get props => [];
}

class GetUserGamingPassLoading extends GetUserGamingPassState {
  @override
  List<Object?> get props => [];
}

class GetUserGamingPassLoaded extends GetUserGamingPassState {
  final List<UserGamingPassModel> userGamingPasses;

  GetUserGamingPassLoaded({required this.userGamingPasses});

  @override
  List<Object?> get props => [userGamingPasses];
}

class GetUserGamingPassError extends GetUserGamingPassState {
  final String message;

  GetUserGamingPassError({required this.message});

  @override
  List<Object?> get props => [message];
}
