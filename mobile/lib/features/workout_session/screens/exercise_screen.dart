import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/good_bad_skip_bar.dart';
import '../widgets/lottie_player.dart';
import '../widgets/session_timer.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End workout?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).endSession();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (session) {
        if (session.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/summary');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final exercise = session.currentExercise;
        if (exercise == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Antrenman'),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SessionTimer(),
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                onPressed: () => _confirmEnd(context, ref),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LottiePlayer(assetPath: exercise.lottieAssetPath),
                          const SizedBox(height: 24),
                          Text(
                            exercise.name,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${exercise.defaultReps} tekrar',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          if (exercise.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(exercise.description,
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                    ),
                  ),
                  GoodBadSkipBar(
                    onResult: (result) =>
                        ref.read(sessionProvider.notifier).submitResult(result),
                  ),
                ],
              ),
              if (session.isCountingDown)
                CountdownOverlay(
                  onDone: () =>
                      ref.read(sessionProvider.notifier).finishCountdown(),
                ),
            ],
          ),
        );
      },
    );
  }
}
