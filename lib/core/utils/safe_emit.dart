import 'package:flutter_bloc/flutter_bloc.dart';

/// Drops states emitted after [close]. A request that finishes after its
/// screen is gone used to throw "Cannot emit new states after calling close".
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
