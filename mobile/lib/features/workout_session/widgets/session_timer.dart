import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';

class SessionTimer extends ConsumerStatefulWidget {
  const SessionTimer({super.key});

  @override
  ConsumerState<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(sessionProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = ref.watch(sessionProvider).whenData((s) => s.remainingSeconds).valueOrNull ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(_format(remaining),
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
