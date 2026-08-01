import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../providers/programs_provider.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Programlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Program',
            onPressed: () => context.push('/programs/new'),
          ),
        ],
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('Henüz bir programın yok.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).startSessionFromProgram(program.id);
                      if (!context.mounted) return;
                      context.go('/session');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(program.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${program.items.length} egzersiz',
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.primary),
                        ],
                      ),
                    ),
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
