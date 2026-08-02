import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/core/models/workout_session.dart';

void main() {
  group('WorkoutSummary.fromJson', () {
    test('parses all fields when present', () {
      final json = {
        'sessionId': 1,
        'totalExercises': 4,
        'goodCount': 2,
        'badCount': 1,
        'skipCount': 1,
        'durationMinutes': 30,
      };

      final summary = WorkoutSummary.fromJson(json);

      expect(summary.sessionId, 1);
      expect(summary.totalExercises, 4);
      expect(summary.goodCount, 2);
      expect(summary.badCount, 1);
      expect(summary.skipCount, 1);
      expect(summary.durationMinutes, 30);
    });

    test('defaults durationMinutes to 0 when null (program-mode session)', () {
      final json = {
        'sessionId': 1,
        'totalExercises': 3,
        'goodCount': 3,
        'badCount': 0,
        'skipCount': 0,
        'durationMinutes': null,
      };

      final summary = WorkoutSummary.fromJson(json);

      expect(summary.durationMinutes, 0);
    });

    test('defaults durationMinutes to 0 when field is missing entirely', () {
      final json = {
        'sessionId': 1,
        'totalExercises': 3,
        'goodCount': 3,
        'badCount': 0,
        'skipCount': 0,
      };

      final summary = WorkoutSummary.fromJson(json);

      expect(summary.durationMinutes, 0);
    });
  });
}
