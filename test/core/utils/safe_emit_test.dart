import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/utils/safe_emit.dart';

class _Counter extends Cubit<int> with SafeEmit<int> {
  _Counter() : super(0);
  void bump() => emit(state + 1);
}

void main() {
  test('emits while open', () {
    final c = _Counter()..bump();
    expect(c.state, 1);
  });

  test('emit after close is ignored instead of throwing', () async {
    final c = _Counter();
    await c.close();
    expect(c.bump, returnsNormally);
    expect(c.state, 0);
  });
}
