import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/core/models/workout_program.dart';

void main() {
  test('WorkoutProgram.fromJson parses id, name, and items', () {
    final json = {
      'id': 1,
      'name': 'Sabah Rutini',
      'items': [
        {'exerciseId': 10, 'sets': 3, 'reps': 12, 'orderIndex': 0},
        {'exerciseId': 11, 'sets': 3, 'reps': 10, 'orderIndex': 1},
      ],
    };

    final program = WorkoutProgram.fromJson(json);

    expect(program.id, 1);
    expect(program.name, 'Sabah Rutini');
    expect(program.items.length, 2);
    expect(program.items[0].exerciseId, 10);
    expect(program.items[0].sets, 3);
    expect(program.items[1].reps, 10);
  });
}
