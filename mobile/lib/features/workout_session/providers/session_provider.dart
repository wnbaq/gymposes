import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../auth/providers/auth_provider.dart';

class SessionState {
  final int? sessionId;
  final Exercise? currentExercise;
  final int remainingSeconds;
  final bool completed;
  final WorkoutSummary? summary;
  final bool isCountingDown;
  final int? sets;
  final int? reps;
  final bool countUp;

  const SessionState({
    this.sessionId,
    this.currentExercise,
    this.remainingSeconds = 0,
    this.completed = false,
    this.summary,
    this.isCountingDown = false,
    this.sets,
    this.reps,
    this.countUp = false,
  });

  SessionState copyWith({
    int? sessionId,
    Exercise? currentExercise,
    int? remainingSeconds,
    bool? completed,
    WorkoutSummary? summary,
    bool? isCountingDown,
    int? sets,
    int? reps,
    bool? countUp,
  }) =>
      SessionState(
        sessionId: sessionId ?? this.sessionId,
        currentExercise: currentExercise ?? this.currentExercise,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completed: completed ?? this.completed,
        summary: summary ?? this.summary,
        isCountingDown: isCountingDown ?? this.isCountingDown,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        countUp: countUp ?? this.countUp,
      );
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionState>>((ref) {
  return SessionNotifier(ref.read(apiClientProvider));
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionState>> {
  final ApiClient _api;

  SessionNotifier(this._api) : super(const AsyncValue.data(SessionState()));

  Future<void> startSession({
    required String location,
    required int durationMinutes,
    required String region,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/workout/start', data: {
        'location': location,
        'durationMinutes': durationMinutes,
        'region': region,
      });
      final response = WorkoutStartResponse.fromJson(
          res.data as Map<String, dynamic>);
      state = AsyncValue.data(SessionState(
        sessionId: response.sessionId,
        currentExercise: response.exercise,
        remainingSeconds: response.remainingSeconds,
        isCountingDown: true,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSessionFromProgram(int programId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/workout/start-from-program', data: {
        'programId': programId,
      });
      final response = WorkoutStartResponse.fromJson(
          res.data as Map<String, dynamic>);
      state = AsyncValue.data(SessionState(
        sessionId: response.sessionId,
        currentExercise: response.exercise,
        remainingSeconds: 0,
        isCountingDown: true,
        countUp: true,
        sets: response.sets,
        reps: response.reps,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void finishCountdown() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(isCountingDown: false));
    });
  }

  Future<void> submitResult(String result) async {
    final current = state.valueOrNull;
    if (current == null || current.sessionId == null) return;

    try {
      final res = await _api.post(
        '/workout/${current.sessionId}/next',
        data: {
          'exerciseId': current.currentExercise!.id,
          'result': result,
        },
      );
      final response = WorkoutNextResponse.fromJson(
          res.data as Map<String, dynamic>);

      if (response.completed) {
        await _completeSession(current.sessionId!);
      } else {
        state = AsyncValue.data(current.copyWith(
          currentExercise: response.exercise,
          completed: false,
          sets: response.sets,
          reps: response.reps,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession() async {
    final current = state.valueOrNull;
    if (current == null || current.sessionId == null) return;
    await _completeSession(current.sessionId!);
  }

  Future<void> _completeSession(int sessionId) async {
    final res = await _api.post('/workout/$sessionId/complete');
    final summary = WorkoutSummary.fromJson(res.data as Map<String, dynamic>);
    state = AsyncValue.data(SessionState(
      sessionId: sessionId,
      completed: true,
      summary: summary,
    ));
  }

  void tick() {
    state.whenData((s) {
      if (s.completed) return;
      if (s.countUp) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds + 1));
      } else if (s.remainingSeconds > 0) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds - 1));
      }
    });
  }

  void reset() => state = const AsyncValue.data(SessionState());
}
