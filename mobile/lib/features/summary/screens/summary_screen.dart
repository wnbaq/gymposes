import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../../workout_setup/providers/workout_setup_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(sessionProvider).valueOrNull?.summary;

    if (summary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Antrenman Tamamlandı!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _StatRow(label: 'Toplam Egzersiz', value: '${summary.totalExercises}'),
              _StatRow(label: 'Good', value: '${summary.goodCount}', color: AppTheme.good),
              _StatRow(label: 'Bad', value: '${summary.badCount}', color: AppTheme.bad),
              _StatRow(label: 'Skip', value: '${summary.skipCount}', color: AppTheme.skip),
              _StatRow(label: 'Süre', value: '${summary.durationMinutes} dakika'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).reset();
                  ref.read(workoutSetupProvider.notifier).reset();
                  context.go('/setup/location');
                },
                child: const Text('Yeni Antrenman'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/history'),
                child: const Text('Geçmişi Gör'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
