import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise.dart';
import '../../auth/providers/auth_provider.dart';

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/exercises');
  return (res.data as List<dynamic>)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList();
});
