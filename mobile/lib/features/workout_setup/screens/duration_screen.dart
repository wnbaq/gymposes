import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workout_setup_provider.dart';

class DurationScreen extends ConsumerWidget {
  const DurationScreen({super.key});

  static const _options = [
    (15, '15 dakika', 'Hızlı antrenman'),
    (30, '30 dakika', 'Standart antrenman'),
    (45, '45 dakika', 'Detaylı antrenman'),
    (60, '60 dakika', 'Tam program'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Ne kadar süre var?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: _options.map((opt) {
            final (mins, label, sub) = opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  onTap: () {
                    ref.read(workoutSetupProvider.notifier).setDuration(mins);
                    context.push('/setup/region');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('$mins',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
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
