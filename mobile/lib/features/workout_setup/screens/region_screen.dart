import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../providers/workout_setup_provider.dart';

class RegionScreen extends ConsumerWidget {
  const RegionScreen({super.key});

  static const _regions = [
    ('UPPER', '💪', 'Üst Vücut', 'Göğüs, sırt, omuz, kol'),
    ('LOWER', '🦵', 'Alt Vücut', 'Bacak, kalça, quadriceps'),
    ('CORE', '🔥', 'Core', 'Karın, bel, denge kasları'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(workoutSetupProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Hangi bölge?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: _regions.map((opt) {
            final (value, icon, title, sub) = opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  onTap: () async {
                    ref.read(workoutSetupProvider.notifier).setRegion(value);
                    await ref.read(sessionProvider.notifier).startSession(
                      location: setup.location!,
                      durationMinutes: setup.durationMinutes!,
                      region: value,
                    );
                    if (!context.mounted) return;
                    context.go('/session');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(sub, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
