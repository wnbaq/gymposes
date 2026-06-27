import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/workout_setup/screens/location_screen.dart';
import '../features/workout_setup/screens/duration_screen.dart';
import '../features/workout_setup/screens/region_screen.dart';
import '../features/workout_session/screens/exercise_screen.dart';
import '../features/summary/screens/summary_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/setup/location', builder: (_, __) => const LocationScreen()),
    GoRoute(path: '/setup/duration', builder: (_, __) => const DurationScreen()),
    GoRoute(path: '/setup/region',   builder: (_, __) => const RegionScreen()),
    GoRoute(path: '/session',        builder: (_, __) => const ExerciseScreen()),
    GoRoute(path: '/summary',        builder: (_, __) => const SummaryScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => _MainScaffold(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const LocationScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);

class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _MainScaffold({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Antrenman'),
          NavigationDestination(icon: Icon(Icons.history),        label: 'Geçmiş'),
          NavigationDestination(icon: Icon(Icons.person),         label: 'Profil'),
        ],
      ),
    );
  }
}
