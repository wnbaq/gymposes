import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/exercise.dart';
import '../../auth/providers/auth_provider.dart';

class ProgramBuilderItem {
  final Exercise exercise;
  final int sets;
  final int reps;

  const ProgramBuilderItem({required this.exercise, required this.sets, required this.reps});

  ProgramBuilderItem copyWith({int? sets, int? reps}) => ProgramBuilderItem(
        exercise: exercise,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
      );
}

class ProgramBuilderState {
  final String name;
  final String? locationFilter;
  final String? muscleGroupFilter;
  final List<ProgramBuilderItem> items;

  const ProgramBuilderState({
    this.name = '',
    this.locationFilter,
    this.muscleGroupFilter,
    this.items = const [],
  });

  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  ProgramBuilderState copyWith({
    String? name,
    String? locationFilter,
    String? muscleGroupFilter,
    List<ProgramBuilderItem>? items,
  }) =>
      ProgramBuilderState(
        name: name ?? this.name,
        locationFilter: locationFilter ?? this.locationFilter,
        muscleGroupFilter: muscleGroupFilter ?? this.muscleGroupFilter,
        items: items ?? this.items,
      );
}

final programBuilderProvider =
    StateNotifierProvider<ProgramBuilderNotifier, ProgramBuilderState>((ref) {
  return ProgramBuilderNotifier(ref.read(apiClientProvider));
});

class ProgramBuilderNotifier extends StateNotifier<ProgramBuilderState> {
  final ApiClient? _api;

  ProgramBuilderNotifier(this._api) : super(const ProgramBuilderState());

  void setName(String name) => state = state.copyWith(name: name);

  void setLocationFilter(String? location) => state = state.copyWith(locationFilter: location);

  void setMuscleGroupFilter(String? muscleGroup) => state = state.copyWith(muscleGroupFilter: muscleGroup);

  void addExercise(Exercise exercise) {
    if (state.items.any((i) => i.exercise.id == exercise.id)) return;
    state = state.copyWith(items: [
      ...state.items,
      ProgramBuilderItem(exercise: exercise, sets: 3, reps: exercise.defaultReps),
    ]);
  }

  void removeExercise(int exerciseId) {
    state = state.copyWith(items: state.items.where((i) => i.exercise.id != exerciseId).toList());
  }

  void updateSets(int exerciseId, int sets) {
    state = state.copyWith(
        items: state.items.map((i) => i.exercise.id == exerciseId ? i.copyWith(sets: sets) : i).toList());
  }

  void updateReps(int exerciseId, int reps) {
    state = state.copyWith(
        items: state.items.map((i) => i.exercise.id == exerciseId ? i.copyWith(reps: reps) : i).toList());
  }

  List<Exercise> filteredExercises(List<Exercise> all) {
    return all.where((e) {
      final locOk = state.locationFilter == null || e.location == state.locationFilter || e.location == 'BOTH';
      final mgOk = state.muscleGroupFilter == null || e.muscleGroup == state.muscleGroupFilter;
      return locOk && mgOk;
    }).toList();
  }

  Future<int> save() async {
    final items = state.items.asMap().entries.map((entry) => {
      'exerciseId': entry.value.exercise.id,
      'sets': entry.value.sets,
      'reps': entry.value.reps,
      'orderIndex': entry.key,
    }).toList();
    final res = await _api!.post('/programs', data: {'name': state.name, 'items': items});
    return res.data['id'] as int;
  }

  void reset() => state = const ProgramBuilderState();
}
