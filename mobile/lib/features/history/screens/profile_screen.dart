import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_stats.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

final statsProvider = FutureProvider<UserStats>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/user/stats');
  return UserStats.fromJson(res.data as Map<String, dynamic>);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
        data: (stats) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center, size: 48, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text('${stats.totalSessions}',
                          style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const Text('Toplam Antrenman',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bölge Dağılımı',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...stats.regionBreakdown.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_regionLabel(e.key)),
                            Text('${e.value} antrenman',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondary)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _regionLabel(String key) {
    return switch (key) {
      'UPPER' => '💪 Üst Vücut',
      'LOWER' => '🦵 Alt Vücut',
      'CORE'  => '🔥 Core',
      _       => key,
    };
  }
}
