import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/features/workout_session/providers/session_provider.dart';

void main() {
  test('SessionState default isCountingDown is false', () {
    const state = SessionState();
    expect(state.isCountingDown, false);
  });

  test('SessionState can be initialized with isCountingDown true', () {
    const state = SessionState(isCountingDown: true);
    expect(state.isCountingDown, true);
  });

  test('SessionState copyWith overrides isCountingDown', () {
    const state = SessionState(isCountingDown: true);
    final copy = state.copyWith(isCountingDown: false);
    expect(copy.isCountingDown, false);
  });

  test('SessionState copyWith preserves isCountingDown when not specified', () {
    const state = SessionState(isCountingDown: true);
    final copy = state.copyWith(remainingSeconds: 10);
    expect(copy.isCountingDown, true);
  });
}
