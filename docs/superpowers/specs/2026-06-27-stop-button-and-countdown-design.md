# Stop Button & 3-2-1 Countdown Design Spec
**Date:** 2026-06-27  
**Scope:** Flutter mobile — workout session UX improvements

---

## 1. Overview

Two independent UX additions to the workout session screen:

1. **Stop Button** — lets the user end the workout at any time via a confirmation dialog
2. **3-2-1 Countdown** — shown once when the session first starts, before the first exercise is revealed

---

## 2. Stop Button

### Placement
An `IconButton` (stop / exit icon, red tint) added to the `AppBar` in `ExerciseScreen`, to the left of the `SessionTimer`.

### Behaviour
1. User taps the stop icon
2. `AlertDialog` appears:
   - Title: "End workout?"
   - Content: "Your progress will be saved."
   - Actions: `[Cancel]` · `[End]`
3. If **Cancel**: dialog dismissed, session continues
4. If **End**: calls `SessionNotifier.endSession()` → `POST /workout/{sessionId}/complete` → navigates to `/summary`

### Implementation
- `endSession()` is a new public method on `SessionNotifier` — it reuses the existing `_completeSession()` private method
- The dialog is built inline in `ExerciseScreen` via `showDialog`
- No backend changes required

---

## 3. 3-2-1 Countdown

### When It Shows
Once only: immediately after `startSession()` succeeds and the first exercise is loaded. It does **not** appear between exercises.

### State Change
`SessionState` gains one new field:

```dart
final bool isCountingDown;  // default: false
```

`startSession()` sets `isCountingDown: true` after receiving the first exercise. After the countdown completes (3 seconds), `SessionNotifier.finishCountdown()` sets it back to `false`.

### UI
`ExerciseScreen` conditionally renders a `CountdownOverlay` widget (new file) when `isCountingDown == true`. The overlay sits on top of the exercise content using a `Stack`.

`CountdownOverlay` is a `StatefulWidget` that:
1. Counts down from 3 to 1, one second per step
2. Displays the current number with a large, bold, animated style (scale animation via `AnimationController`)
3. After showing "1" for one second, calls `onDone` callback
4. `onDone` → `ref.read(sessionProvider.notifier).finishCountdown()`

The overlay background is semi-transparent black (`Colors.black87`) so the exercise content is visible beneath it.

---

## 4. Files Changed

| File | Change |
|------|--------|
| `session_provider.dart` | Add `isCountingDown` to `SessionState`; set to `true` in `startSession()`; add `finishCountdown()` method; add `endSession()` public method |
| `exercise_screen.dart` | Wrap body in `Stack`; render `CountdownOverlay` conditionally; add stop `IconButton` to AppBar + `showDialog` logic |
| `widgets/countdown_overlay.dart` | New widget — countdown animation + `onDone` callback |

---

## 5. Out of Scope

- Countdown between exercises (only session start)
- Pause functionality
- Sound / haptic feedback during countdown
