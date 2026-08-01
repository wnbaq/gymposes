import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymposesapp/core/models/exercise.dart';
import 'package:gymposesapp/features/programs/providers/program_builder_provider.dart';

Exercise _ex(int id, String name, {String location = 'BOTH', String muscleGroup = 'UPPER', int defaultReps = 12}) =>
    Exercise(
      id: id,
      name: name,
      description: '',
      defaultReps: defaultReps,
      lottieAssetPath: 'x.json',
      difficultyScore: 5.0,
      location: location,
      muscleGroup: muscleGroup,
    );

void main() {
  test('canSave is false with no name or items', () {
    const state = ProgramBuilderState();
    expect(state.canSave, false);
  });

  test('canSave is true once name is set and an item is added', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setName('Sabah Rutini');
    notifier.addExercise(_ex(1, 'Squat', defaultReps: 12));
    expect(notifier.state.canSave, true);
  });

  test('addExercise defaults to 3 sets and the exercise defaultReps', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat', defaultReps: 15));
    expect(notifier.state.items.single.sets, 3);
    expect(notifier.state.items.single.reps, 15);
  });

  test('addExercise ignores a duplicate exercise id', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(1, 'Squat'));
    expect(notifier.state.items.length, 1);
  });

  test('removeExercise removes the matching item', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(2, 'Lunge'));
    notifier.removeExercise(1);
    expect(notifier.state.items.length, 1);
    expect(notifier.state.items.single.exercise.id, 2);
  });

  test('updateSets and updateReps change only the matching item', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(2, 'Lunge'));
    notifier.updateSets(1, 5);
    notifier.updateReps(2, 20);
    expect(notifier.state.items[0].sets, 5);
    expect(notifier.state.items[1].reps, 20);
  });

  test('filteredExercises filters by location, including BOTH', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setLocationFilter('HOME');
    final all = [
      _ex(1, 'Squat', location: 'BOTH'),
      _ex(2, 'Barfiks', location: 'GYM'),
      _ex(3, 'Dips', location: 'HOME'),
    ];
    final filtered = notifier.filteredExercises(all);
    expect(filtered.map((e) => e.id), containsAll([1, 3]));
    expect(filtered.map((e) => e.id), isNot(contains(2)));
  });

  test('filteredExercises filters by muscle group', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setMuscleGroupFilter('CORE');
    final all = [
      _ex(1, 'Squat', muscleGroup: 'LOWER'),
      _ex(2, 'Plank', muscleGroup: 'CORE'),
    ];
    final filtered = notifier.filteredExercises(all);
    expect(filtered.map((e) => e.id), [2]);
  });

  test('reset clears name and items', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setName('Sabah Rutini');
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.reset();
    expect(notifier.state.name, '');
    expect(notifier.state.items, isEmpty);
  });
}
