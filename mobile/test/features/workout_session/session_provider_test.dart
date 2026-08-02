import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/core/api/api_client.dart';
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

  test('SessionState default sets, reps, and countUp', () {
    const state = SessionState();
    expect(state.sets, null);
    expect(state.reps, null);
    expect(state.countUp, false);
  });

  test('SessionState copyWith sets sets/reps/countUp', () {
    const state = SessionState();
    final copy = state.copyWith(sets: 3, reps: 12, countUp: true);
    expect(copy.sets, 3);
    expect(copy.reps, 12);
    expect(copy.countUp, true);
  });

  group('SessionNotifier.tick', () {
    test('increments remainingSeconds when countUp is true', () {
      final notifier = SessionNotifier(ApiClient());
      notifier.state = const AsyncValue.data(
        SessionState(countUp: true, remainingSeconds: 5),
      );

      notifier.tick();

      expect(notifier.state.value!.remainingSeconds, 6);
    });

    test('decrements remainingSeconds when countUp is false and time remains', () {
      final notifier = SessionNotifier(ApiClient());
      notifier.state = const AsyncValue.data(
        SessionState(countUp: false, remainingSeconds: 5),
      );

      notifier.tick();

      expect(notifier.state.value!.remainingSeconds, 4);
    });

    test('does not decrement below zero when countUp is false', () {
      final notifier = SessionNotifier(ApiClient());
      notifier.state = const AsyncValue.data(
        SessionState(countUp: false, remainingSeconds: 0),
      );

      notifier.tick();

      expect(notifier.state.value!.remainingSeconds, 0);
    });

    test('does not change remainingSeconds once completed', () {
      final notifier = SessionNotifier(ApiClient());
      notifier.state = const AsyncValue.data(
        SessionState(countUp: true, remainingSeconds: 5, completed: true),
      );

      notifier.tick();

      expect(notifier.state.value!.remainingSeconds, 5);
    });
  });
}
