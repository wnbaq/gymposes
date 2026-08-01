# Custom Workout Program Design Spec
**Date:** 2026-08-01
**Scope:** Backend (Spring Boot) + Flutter mobile — user-built workout programs

---

## 1. Overview

Today, exercise selection during a workout is fully driven by `AdaptiveService` — the user never picks their own exercises. This feature adds an alternative path: the user can browse the exercise catalog, assemble their own ordered list of exercises with a chosen set/rep count for each, save it as a named program, and start a workout session that walks through that fixed list instead of the adaptive engine.

A new entry point — a "Programlarım" button in the `AppBar` of the Antrenman tab's home screen (`LocationScreen`) — leads to a list of the user's saved programs and a builder for creating new ones.

---

## 2. Data Model (Backend)

Two new entities:

```java
@Entity @Table(name = "workout_programs")
class WorkoutProgram {
    Long id;
    User user;              // @ManyToOne
    String name;
    LocalDateTime createdAt;
}

@Entity @Table(name = "workout_program_items")
class WorkoutProgramItem {
    Long id;
    WorkoutProgram program; // @ManyToOne
    Exercise exercise;      // @ManyToOne
    Integer sets;
    Integer reps;
    Integer orderIndex;
}
```

`WorkoutSession` gains two nullable fields:

```java
WorkoutProgram program;      // @ManyToOne, nullable — null means "adaptive session" (existing behavior)
Integer currentItemIndex;    // position within program.items, null when program is null
```

A session is in **program mode** whenever `session.program != null`. In that mode, `AdaptiveService` is never consulted for exercise selection — the next exercise comes from `program.items` ordered by `orderIndex`.

---

## 3. Backend Endpoints

| Method | Endpoint | Description |
|--------|----------|--------------|
| `GET` | `/exercises?location=&muscleGroup=` | List exercises, optionally filtered. New `ExerciseController`. Used to populate the builder screen. |
| `GET` | `/programs` | List the current user's saved programs, each with its items (exercise + sets + reps). New `ProgramController` + `ProgramService`. |
| `POST` | `/programs` | Body: `{ name, items: [{ exerciseId, sets, reps, orderIndex }] }`. Rejects (400, via existing `GlobalExceptionHandler`) if `name` is blank or `items` is empty. |
| `POST` | `/workout/start-from-program` | Body: `{ programId }`. Creates a `WorkoutSession` with `program` set and `currentItemIndex = 0`; `location`/`region`/`durationMinutes` stay null (unused in program mode). Returns the first item's exercise + sets + reps, same response shape as `/workout/start`. |

### Response shape changes

`WorkoutStartResponse` and `WorkoutNextResponse` gain optional `sets` and `reps` fields (`Integer`, nullable) alongside the existing `exercise` field. Populated only in program mode; `null` in adaptive mode, preserving current behavior.

### `WorkoutService` branching

- `nextExercise()`: if `session.program != null`, increment `currentItemIndex`; if it now exceeds the last item index, return `completed = true`; otherwise return the item at that index (exercise + sets + reps). If `session.program == null`, existing elapsed-time + `AdaptiveService` logic is unchanged.
- `completeSession()` and `SessionLog` recording are unchanged — a `SessionLog` row is still written per exercise result, referencing the exercise as before. `AdaptiveService.updateUserScore` / `updateTargetScore` are **not** called in program mode (there's no adaptive state to update).

---

## 4. Mobile Screens & Flow

### Entry point
`LocationScreen` AppBar gains an `IconButton` (`Icons.list_alt`, tooltip "Programlarım") navigating to `/programs`.

### `ProgramListScreen` (`/programs`)
- Fetches and lists saved programs (name + exercise count) via `programsProvider` (`FutureProvider` wrapping `GET /programs`)
- Tapping a program calls `startSessionFromProgram(programId)` then navigates to `/session`
- A FAB / top button "Yeni Program Oluştur" navigates to `/programs/new`

### `ProgramBuilderScreen` (`/programs/new`)
- `TextField` for the program name
- Filter chips for location (Ev/Salon) and muscle group (Üst/Alt/Core), driving a filtered view over all exercises (fetched once via `GET /exercises`)
- Scrollable exercise list, each row with a "+ Ekle" action
- "Seçilenler" section below: each added exercise shows its name plus set/rep steppers (default: 3 sets × the exercise's `defaultReps`) and a remove action
- "Kaydet ve Başlat" button, disabled until name is non-empty and at least one exercise is selected — calls `POST /programs`, then `startSessionFromProgram` with the returned id, then navigates to `/session`

### Providers
- `programBuilderProvider` (`StateNotifier`): name, filters, fetched exercise catalog, selected items list
- `programsProvider` (`FutureProvider`): saved programs list
- `SessionNotifier` gains `startSessionFromProgram(int programId)`, mirroring the existing `startSession()` but posting to `/workout/start-from-program`

### `ExerciseScreen`
Unchanged apart from the reps label: if the current response carries non-null `sets`/`reps`, render `"$sets set x $reps tekrar"`; otherwise keep the existing `"${exercise.defaultReps} tekrar"` behavior. The rest of the screen (timer, Good/Bad/Skip, countdown, stop button) is identical in both modes — a program-mode session is still a normal `WorkoutSession` with logs and a summary at the end.

---

## 5. Error Handling

- Client-side: "Kaydet ve Başlat" stays disabled until validation passes (non-empty name, ≥1 exercise) — no need to round-trip to the backend for this
- Backend: blank name or empty items list on `POST /programs` → `IllegalArgumentException` → 400 via the existing `GlobalExceptionHandler`, same pattern as auth errors
- `GET /exercises` / `GET /programs` failures on the builder/list screens follow the existing `Text('Hata: $e')` pattern already used in `ExerciseScreen`

---

## 6. Testing

- Backend: extend `WorkoutServiceTest` with program-mode cases (next exercise follows `orderIndex`, `completed = true` after the last item); new tests for `ProgramService` create/list
- Mobile: extend `session_provider_test.dart` with a `startSessionFromProgram` case, following the existing `startSession` test pattern

---

## 7. Out of Scope

- Editing or deleting saved programs
- Reordering items after adding them (order = add order)
- Per-set tracking during a session (a program-mode exercise is still evaluated once via Good/Bad/Skip, sets/reps are informational only — matches the "tek kart" decision)
- Sharing programs between users
