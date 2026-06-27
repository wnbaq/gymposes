# Stop Button & 3-2-1 Countdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a stop-with-confirmation button to the workout AppBar and a 3-2-1 countdown overlay shown once when the session first starts.

**Architecture:** State-driven — `SessionState` gains an `isCountingDown` flag set to `true` by `startSession()`; a new `CountdownOverlay` widget displays the countdown and calls `finishCountdown()` when done. The stop button lives in the AppBar and calls `endSession()` after dialog confirmation.

**Tech Stack:** Flutter 3.x, Dart (null-safe), Riverpod (StateNotifierProvider), GoRouter

## Global Constraints

- No backend changes required
- Follow existing widget conventions: `ConsumerWidget` / `ConsumerStatefulWidget`
- Routing via `context.go(...)` (GoRouter)
- All new files under `mobile/lib/features/workout_session/`

---

### Task 1: Extend SessionState and SessionNotifier

**Files:**
- Modify: `mobile/lib/features/workout_session/providers/session_provider.dart`
- Test: `mobile/test/features/workout_session/session_provider_test.dart`

**Interfaces:**
- Produces:
  - `SessionState.isCountingDown` → `bool` (default `false`)
  - `SessionNotifier.finishCountdown()` → `void` (sets `isCountingDown: false`)
  - `SessionNotifier.endSession()` → `Future<void>` (calls `_completeSession`)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/workout_session/session_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposes/features/workout_session/providers/session_provider.dart';

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
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd mobile
flutter test test/features/workout_session/session_provider_test.dart
```

Expected: FAIL — `isCountingDown` field does not exist on `SessionState`.

- [ ] **Step 3: Update `session_provider.dart`**

Replace the full file contents:

```dart
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

  const SessionState({
    this.sessionId,
    this.currentExercise,
    this.remainingSeconds = 0,
    this.completed = false,
    this.summary,
    this.isCountingDown = false,
  });

  SessionState copyWith({
    int? sessionId,
    Exercise? currentExercise,
    int? remainingSeconds,
    bool? completed,
    WorkoutSummary? summary,
    bool? isCountingDown,
  }) =>
      SessionState(
        sessionId: sessionId ?? this.sessionId,
        currentExercise: currentExercise ?? this.currentExercise,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completed: completed ?? this.completed,
        summary: summary ?? this.summary,
        isCountingDown: isCountingDown ?? this.isCountingDown,
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
      if (s.remainingSeconds > 0 && !s.completed) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds - 1));
      }
    });
  }

  void reset() => state = const AsyncValue.data(SessionState());
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
cd mobile
flutter test test/features/workout_session/session_provider_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/workout_session/providers/session_provider.dart mobile/test/features/workout_session/session_provider_test.dart
git commit -m "feat: add isCountingDown to SessionState, finishCountdown and endSession to SessionNotifier"
```

---

### Task 2: CountdownOverlay Widget

**Files:**
- Create: `mobile/lib/features/workout_session/widgets/countdown_overlay.dart`
- Test: `mobile/test/features/workout_session/widgets/countdown_overlay_test.dart`

**Interfaces:**
- Produces: `CountdownOverlay({required VoidCallback onDone, super.key})` — fullscreen dark overlay counting 3→2→1, calls `onDone` after "1" is shown for 1 second

- [ ] **Step 1: Write the failing widget tests**

Create `mobile/test/features/workout_session/widgets/countdown_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposes/features/workout_session/widgets/countdown_overlay.dart';

void main() {
  testWidgets('shows 3 on first frame', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows 2 after 1 second', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows 1 after 2 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () {})),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('calls onDone after 3 seconds', (tester) async {
    bool called = false;
    await tester.pumpWidget(
      MaterialApp(home: CountdownOverlay(onDone: () => called = true)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(called, true);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd mobile
flutter test test/features/workout_session/widgets/countdown_overlay_test.dart
```

Expected: FAIL — `CountdownOverlay` not found.

- [ ] **Step 3: Create `countdown_overlay.dart`**

Create `mobile/lib/features/workout_session/widgets/countdown_overlay.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const CountdownOverlay({required this.onDone, super.key});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  Timer? _timer;
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count == 1) {
        t.cancel();
        widget.onDone();
      } else {
        setState(() => _count--);
        _anim.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            '$_count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
cd mobile
flutter test test/features/workout_session/widgets/countdown_overlay_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/workout_session/widgets/countdown_overlay.dart mobile/test/features/workout_session/widgets/countdown_overlay_test.dart
git commit -m "feat: add CountdownOverlay widget with 3-2-1 scale animation"
```

---

### Task 3: Wire Up ExerciseScreen

**Files:**
- Modify: `mobile/lib/features/workout_session/screens/exercise_screen.dart`

**Interfaces:**
- Consumes:
  - `SessionState.isCountingDown` (bool) — from Task 1
  - `SessionNotifier.finishCountdown()` — from Task 1
  - `SessionNotifier.endSession()` — from Task 1
  - `CountdownOverlay({required VoidCallback onDone})` — from Task 2

- [ ] **Step 1: Replace `exercise_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/good_bad_skip_bar.dart';
import '../widgets/lottie_player.dart';
import '../widgets/session_timer.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End workout?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).endSession();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);

    return sessionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (session) {
        if (session.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/summary');
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final exercise = session.currentExercise;
        if (exercise == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Antrenman'),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SessionTimer(),
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined,
                    color: Colors.red),
                onPressed: () => _confirmEnd(context, ref),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LottiePlayer(assetPath: exercise.lottieAssetPath),
                          const SizedBox(height: 24),
                          Text(
                            exercise.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${exercise.defaultReps} tekrar',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          if (exercise.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(exercise.description,
                                style:
                                    const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                    ),
                  ),
                  GoodBadSkipBar(
                    onResult: (result) => ref
                        .read(sessionProvider.notifier)
                        .submitResult(result),
                  ),
                ],
              ),
              if (session.isCountingDown)
                CountdownOverlay(
                  onDone: () =>
                      ref.read(sessionProvider.notifier).finishCountdown(),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```
cd mobile
flutter analyze lib/features/workout_session/screens/exercise_screen.dart
```

Expected: No errors or warnings.

- [ ] **Step 3: Manual test — stop button**

Run `flutter run`, start a workout session, then:
1. Tap the red stop icon (top-right of AppBar, next to the timer)
2. Verify dialog appears: title "End workout?", body "Your progress will be saved.", buttons "Cancel" and "End"
3. Tap **Cancel** → dialog closes, session continues normally
4. Tap stop again → tap **End** → app navigates to `/summary` and shows workout summary

- [ ] **Step 4: Manual test — 3-2-1 countdown**

Start a new workout from the setup flow, then:
1. Verify a dark overlay appears showing "3" in large white text immediately
2. After 1 second: "3" changes to "2" with a scale-in animation
3. After 2 seconds: "2" changes to "1"
4. After 3 seconds: overlay disappears and the exercise + Good/Bad/Skip bar are visible
5. Verify the stop button is NOT blocked by the overlay (it sits in the AppBar above the Stack body)

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/workout_session/screens/exercise_screen.dart
git commit -m "feat: wire stop button and countdown overlay into ExerciseScreen"
```
