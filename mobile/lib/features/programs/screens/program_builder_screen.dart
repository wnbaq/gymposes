import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../providers/exercise_catalog_provider.dart';
import '../providers/program_builder_provider.dart';
import '../providers/programs_provider.dart';

class ProgramBuilderScreen extends ConsumerWidget {
  const ProgramBuilderScreen({super.key});

  static const _locations = [(null, 'Tümü'), ('HOME', 'Ev'), ('GYM', 'Salon')];
  static const _muscleGroups = [(null, 'Tümü'), ('UPPER', 'Üst'), ('LOWER', 'Alt'), ('CORE', 'Core')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(programBuilderProvider);
    final builderNotifier = ref.read(programBuilderProvider.notifier);
    final catalogAsync = ref.watch(exerciseCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Yeni Program')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Program adı'),
              onChanged: builderNotifier.setName,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              children: _locations.map((opt) {
                final (value, label) = opt;
                return ChoiceChip(
                  label: Text(label),
                  selected: builderState.locationFilter == value,
                  onSelected: (_) => builderNotifier.setLocationFilter(value),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              children: _muscleGroups.map((opt) {
                final (value, label) = opt;
                return ChoiceChip(
                  label: Text(label),
                  selected: builderState.muscleGroupFilter == value,
                  onSelected: (_) => builderNotifier.setMuscleGroupFilter(value),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: catalogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (all) {
                final filtered = builderNotifier.filteredExercises(all);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...filtered.map((exercise) => ListTile(
                          title: Text(exercise.name),
                          subtitle: Text('${exercise.defaultReps} tekrar (varsayılan)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                            onPressed: () => builderNotifier.addExercise(exercise),
                          ),
                        )),
                    if (builderState.items.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Seçilenler', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...builderState.items.map((item) => ListTile(
                            title: Text(item.exercise.name),
                            subtitle: Text('${item.sets} set x ${item.reps} tekrar'),
                            leading: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.bad),
                              onPressed: () => builderNotifier.removeExercise(item.exercise.id),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Stepper(
                                  value: item.sets,
                                  onChanged: (v) => builderNotifier.updateSets(item.exercise.id, v),
                                ),
                                const SizedBox(width: 8),
                                _Stepper(
                                  value: item.reps,
                                  onChanged: (v) => builderNotifier.updateReps(item.exercise.id, v),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: builderState.canSave
                  ? () async {
                      final programId = await builderNotifier.save();
                      ref.invalidate(programsProvider);
                      builderNotifier.reset();
                      await ref.read(sessionProvider.notifier).startSessionFromProgram(programId);
                      if (!context.mounted) return;
                      context.go('/session');
                    }
                  : null,
              child: const Text('Kaydet ve Başlat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value'),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
