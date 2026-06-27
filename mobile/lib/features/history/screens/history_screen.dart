import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';

final historyProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/user/history');
  return res.data as List<dynamic>;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Antrenman Geçmişi')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
                child: Text('Henüz antrenman yok.',
                    style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i] as Map<String, dynamic>;
              final date = DateTime.tryParse(s['startedAt'] as String? ?? '');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Color(0xFF6C63FF)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s['region']} • ${s['location']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              date != null
                                  ? DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(date)
                                  : '-',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${s['durationMinutes']} dk',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF48C9B0)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
