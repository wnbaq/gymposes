import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/workout_program.dart';
import '../../auth/providers/auth_provider.dart';

final programsProvider = FutureProvider<List<WorkoutProgram>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/programs');
  return (res.data as List<dynamic>)
      .map((p) => WorkoutProgram.fromJson(p as Map<String, dynamic>))
      .toList();
});
