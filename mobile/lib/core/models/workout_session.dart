import 'exercise.dart';

class WorkoutStartResponse {
  final int sessionId;
  final Exercise exercise;
  final int remainingSeconds;
  final int? sets;
  final int? reps;

  const WorkoutStartResponse({
    required this.sessionId,
    required this.exercise,
    required this.remainingSeconds,
    this.sets,
    this.reps,
  });

  factory WorkoutStartResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutStartResponse(
        sessionId: json['sessionId'] as int,
        exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        remainingSeconds: json['remainingSeconds'] as int,
        sets: json['sets'] as int?,
        reps: json['reps'] as int?,
      );
}

class WorkoutNextResponse {
  final Exercise? exercise;
  final bool completed;
  final int? sets;
  final int? reps;

  const WorkoutNextResponse({this.exercise, required this.completed, this.sets, this.reps});

  factory WorkoutNextResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutNextResponse(
        exercise: json['exercise'] != null
            ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>)
            : null,
        completed: (json['completed'] as bool?) ?? false,
        sets: json['sets'] as int?,
        reps: json['reps'] as int?,
      );
}

class WorkoutSummary {
  final int sessionId;
  final int totalExercises;
  final int goodCount;
  final int badCount;
  final int skipCount;
  final int durationMinutes;

  const WorkoutSummary({
    required this.sessionId,
    required this.totalExercises,
    required this.goodCount,
    required this.badCount,
    required this.skipCount,
    required this.durationMinutes,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) => WorkoutSummary(
    sessionId: json['sessionId'] as int,
    totalExercises: json['totalExercises'] as int,
    goodCount: json['goodCount'] as int,
    badCount: json['badCount'] as int,
    skipCount: json['skipCount'] as int,
    durationMinutes: json['durationMinutes'] as int,
  );
}
