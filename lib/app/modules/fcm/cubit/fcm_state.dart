part of 'fcm_cubit.dart';

abstract class FcmState extends Equatable {
  const FcmState();
}

class FcmInitial extends FcmState {
  @override
  List<Object> get props => [];
}

class FcmTokenRegistered extends FcmState {
  @override
  List<Object> get props => [];
}

class FcmTokenLoading extends FcmState {
  @override
  List<Object> get props => [];
}

class FcmTokenError extends FcmState {
  @override
  List<Object> get props => [];
}
