# GymPoses Flutter — Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter uygulaması — auth, workout setup, animasyonlu egzersiz session'ı, Good/Bad/Skip değerlendirmesi, geçmiş ve profil ekranları.

**Architecture:** Thin Client. Tüm iş mantığı backend'de. Flutter sadece UI ve HTTP çağrıları yapar. Riverpod state management, Dio HTTP, Lottie animasyon, GoRouter navigasyon.

**Tech Stack:** Flutter 3.x, flutter_riverpod 2.5.x, dio 5.x, lottie 3.x, go_router 13.x, flutter_secure_storage 9.x

**Prerequisite:** Backend çalışıyor ve `http://localhost:8080` adresinde erişilebilir. Android emülatör için `http://10.0.2.2:8080` kullanılır.

---

## File Map

```
mobile/
├── pubspec.yaml
├── assets/
│   └── lottie/
│       └── placeholder.json       ← gerçek Lottie dosyaları buraya
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   │   └── api_client.dart
│   │   ├── models/
│   │   │   ├── exercise.dart
│   │   │   ├── workout_session.dart   ← WorkoutStartResponse, WorkoutNextResponse, WorkoutSummary
│   │   │   └── user_stats.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   ├── workout_setup/
│   │   │   ├── providers/
│   │   │   │   └── workout_setup_provider.dart
│   │   │   └── screens/
│   │   │       ├── location_screen.dart
│   │   │       ├── duration_screen.dart
│   │   │       └── region_screen.dart
│   │   ├── workout_session/
│   │   │   ├── providers/
│   │   │   │   └── session_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── exercise_screen.dart
│   │   │   └── widgets/
│   │   │       ├── lottie_player.dart
│   │   │       ├── session_timer.dart
│   │   │       └── good_bad_skip_bar.dart
│   │   ├── summary/
│   │   │   └── screens/
│   │   │       └── summary_screen.dart
│   │   └── history/
│   │       └── screens/
│   │           ├── history_screen.dart
│   │           └── profile_screen.dart
│   └── routing/
│       └── app_router.dart
└── test/
    ├── providers/
    │   ├── auth_provider_test.dart
    │   └── session_provider_test.dart
    └── widgets/
        └── good_bad_skip_bar_test.dart
```

---

## Task 10: Flutter Proje Kurulumu

**Files:**
- Create: `mobile/pubspec.yaml`
- Create: `mobile/lib/main.dart`
- Create: `mobile/assets/lottie/placeholder.json`

- [ ] **Step 1: Flutter projesi oluştur**

```bash
# Çalışma dizini: c:\Users\wnbaq\OneDrive\Belgeler\GymPoses
flutter create mobile --org com.gymposes --project-name gymposesapp
cd mobile
```

- [ ] **Step 2: pubspec.yaml bağımlılıklarını güncelle**

`mobile/pubspec.yaml` içindeki `dependencies` ve `dev_dependencies` bölümlerini şununla değiştir:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  dio: ^5.4.3
  lottie: ^3.1.2
  go_router: ^13.2.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/lottie/
```

- [ ] **Step 3: Lottie assets klasörünü ve placeholder'ı oluştur**

```bash
mkdir -p mobile/assets/lottie
```

`mobile/assets/lottie/placeholder.json` dosyasına minimal geçerli Lottie JSON yaz:

```json
{
  "v": "5.7.4",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 200,
  "h": 200,
  "nm": "Placeholder",
  "ddd": 0,
  "assets": [],
  "layers": [{
    "ddd": 0, "ind": 1, "ty": 4, "nm": "Shape",
    "ks": { "o": {"a":0,"k":100}, "r": {"a":1,"k":[{"i":{"x":[0.833],"y":[0.833]},"o":{"x":[0.167],"y":[0.167]},"t":0,"s":[0]},{"t":60,"s":[360]}]}, "p": {"a":0,"k":[100,100,0]}, "s": {"a":0,"k":[100,100,100]} },
    "shapes": [{"ty":"el","s":{"a":0,"k":[80,80]},"p":{"a":0,"k":[0,0]},"nm":"Ellipse"},{"ty":"fl","c":{"a":0,"k":[0.424,0.388,1,1]},"o":{"a":0,"k":100},"nm":"Fill"}],
    "ip": 0, "op": 60, "sr": 1, "st": 0
  }]
}
```

- [ ] **Step 4: Bağımlılıkları yükle**

```bash
cd mobile && flutter pub get
```
Expected: tüm paketler indirilir, hata yok

- [ ] **Step 5: Commit**

```bash
git add mobile/
git commit -m "chore: initialize Flutter project with dependencies"
```

---

## Task 11: Core Katmanı (API, Models, Theme, Storage)

**Files:**
- Create: `mobile/lib/core/storage/secure_storage.dart`
- Create: `mobile/lib/core/api/api_client.dart`
- Create: `mobile/lib/core/models/exercise.dart`
- Create: `mobile/lib/core/models/workout_session.dart`
- Create: `mobile/lib/core/models/user_stats.dart`
- Create: `mobile/lib/core/theme/app_theme.dart`

- [ ] **Step 1: SecureStorage yaz**

```dart
// lib/core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
```

- [ ] **Step 2: ApiClient yaz**

```dart
// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  // Android emülatör için 10.0.2.2, gerçek cihaz/iOS için localhost veya IP
  static const baseUrl = 'http://10.0.2.2:8080';

  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        handler.next(e);
      },
    ));
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> get(String path) => _dio.get(path);
}
```

- [ ] **Step 3: Exercise modeli yaz**

```dart
// lib/core/models/exercise.dart
class Exercise {
  final int id;
  final String name;
  final String description;
  final int defaultReps;
  final String lottieAssetPath;
  final double difficultyScore;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultReps,
    required this.lottieAssetPath,
    required this.difficultyScore,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as int,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    defaultReps: (json['defaultReps'] as int?) ?? 12,
    lottieAssetPath: (json['lottieAssetPath'] as String?) ?? 'placeholder.json',
    difficultyScore: (json['difficultyScore'] as num?)?.toDouble() ?? 5.0,
  );
}
```

- [ ] **Step 4: WorkoutSession modelleri yaz**

```dart
// lib/core/models/workout_session.dart
import 'exercise.dart';

class WorkoutStartResponse {
  final int sessionId;
  final Exercise exercise;
  final int remainingSeconds;

  const WorkoutStartResponse({
    required this.sessionId,
    required this.exercise,
    required this.remainingSeconds,
  });

  factory WorkoutStartResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutStartResponse(
        sessionId: json['sessionId'] as int,
        exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        remainingSeconds: json['remainingSeconds'] as int,
      );
}

class WorkoutNextResponse {
  final Exercise? exercise;
  final bool completed;

  const WorkoutNextResponse({this.exercise, required this.completed});

  factory WorkoutNextResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutNextResponse(
        exercise: json['exercise'] != null
            ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>)
            : null,
        completed: (json['completed'] as bool?) ?? false,
      );
}

class WorkoutSummary {
  final int sessionId;
  final int totalExercises;
  final int goodCount;
  final int badCount;
  final int skipCount;
  final int durationMinutes;

  const WorkoutSummary({
    required this.sessionId,
    required this.totalExercises,
    required this.goodCount,
    required this.badCount,
    required this.skipCount,
    required this.durationMinutes,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) => WorkoutSummary(
    sessionId: json['sessionId'] as int,
    totalExercises: json['totalExercises'] as int,
    goodCount: json['goodCount'] as int,
    badCount: json['badCount'] as int,
    skipCount: json['skipCount'] as int,
    durationMinutes: json['durationMinutes'] as int,
  );
}
```

- [ ] **Step 5: UserStats modeli yaz**

```dart
// lib/core/models/user_stats.dart
class UserStats {
  final int totalSessions;
  final Map<String, int> regionBreakdown;

  const UserStats({required this.totalSessions, required this.regionBreakdown});

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalSessions: json['totalSessions'] as int,
    regionBreakdown: Map<String, int>.from(
      (json['regionBreakdown'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
    ),
  );
}
```

- [ ] **Step 6: AppTheme yaz**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF48C9B0);
  static const Color good = Color(0xFF4CAF50);
  static const Color bad = Color(0xFFE91E63);
  static const Color skip = Color(0xFF9C27B0);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      surface: const Color(0xFFF5F5F5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
```

- [ ] **Step 7: Derlemeyi doğrula**

```bash
cd mobile && flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/core/
git commit -m "feat: add core layer (API client, models, theme, secure storage)"
```

---

## Task 12: Auth Feature

**Files:**
- Create: `mobile/lib/features/auth/providers/auth_provider.dart`
- Create: `mobile/lib/features/auth/screens/login_screen.dart`
- Create: `mobile/lib/features/auth/screens/register_screen.dart`
- Test: `mobile/test/providers/auth_provider_test.dart`

- [ ] **Step 1: AuthProvider yaz**

```dart
// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/register',
          data: {'email': email, 'password': password});
      await SecureStorage.saveToken(res.data['token'] as String);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/login',
          data: {'email': email, 'password': password});
      await SecureStorage.saveToken(res.data['token'] as String);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = const AsyncValue.data(null);
  }
}
```

- [ ] **Step 2: LoginScreen yaz**

```dart
// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final authState = ref.read(authProvider);
    authState.when(
      data: (_) => context.go('/setup/location'),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız: $e'))),
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GymPoses',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Antrenmanına başla',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Geçerli email girin',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 karakter',
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Giriş Yap'),
                      ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Hesabın yok mu? Kayıt ol'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: RegisterScreen yaz**

```dart
// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final authState = ref.read(authProvider);
    authState.when(
      data: (_) => context.go('/setup/location'),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt başarısız: $e'))),
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Geçerli email girin',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 karakter',
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(onPressed: _submit, child: const Text('Kayıt Ol')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/auth/
git commit -m "feat: add auth screens and provider"
```

---

## Task 13: Workout Setup Feature (3 Ekran)

**Files:**
- Create: `mobile/lib/features/workout_setup/providers/workout_setup_provider.dart`
- Create: `mobile/lib/features/workout_setup/screens/location_screen.dart`
- Create: `mobile/lib/features/workout_setup/screens/duration_screen.dart`
- Create: `mobile/lib/features/workout_setup/screens/region_screen.dart`

- [ ] **Step 1: WorkoutSetupProvider yaz**

```dart
// lib/features/workout_setup/providers/workout_setup_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutSetup {
  final String? location;       // 'HOME' | 'GYM'
  final int? durationMinutes;
  final String? region;         // 'UPPER' | 'LOWER' | 'CORE'

  const WorkoutSetup({this.location, this.durationMinutes, this.region});

  WorkoutSetup copyWith({String? location, int? durationMinutes, String? region}) =>
      WorkoutSetup(
        location: location ?? this.location,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        region: region ?? this.region,
      );

  bool get isComplete =>
      location != null && durationMinutes != null && region != null;
}

final workoutSetupProvider =
    StateNotifierProvider<WorkoutSetupNotifier, WorkoutSetup>((ref) {
  return WorkoutSetupNotifier();
});

class WorkoutSetupNotifier extends StateNotifier<WorkoutSetup> {
  WorkoutSetupNotifier() : super(const WorkoutSetup());

  void setLocation(String loc) => state = state.copyWith(location: loc);
  void setDuration(int mins) => state = state.copyWith(durationMinutes: mins);
  void setRegion(String reg) => state = state.copyWith(region: reg);
  void reset() => state = const WorkoutSetup();
}
```

- [ ] **Step 2: LocationScreen yaz**

```dart
// lib/features/workout_setup/screens/location_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workout_setup_provider.dart';

class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Nerede antrenman yapacaksın?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OptionCard(
              icon: '🏠',
              title: 'Evde',
              subtitle: 'Ekipman gerektirmeyen egzersizler',
              onTap: () {
                ref.read(workoutSetupProvider.notifier).setLocation('HOME');
                context.push('/setup/duration');
              },
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: '🏋️',
              title: 'Spor Salonu',
              subtitle: 'Ekipman gerektiren egzersizler dahil',
              onTap: () {
                ref.read(workoutSetupProvider.notifier).setLocation('GYM');
                context.push('/setup/duration');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: DurationScreen yaz**

```dart
// lib/features/workout_setup/screens/duration_screen.dart
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
                            color: AppTheme.primary.withOpacity(0.1),
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
```

- [ ] **Step 4: RegionScreen yaz**

```dart
// lib/features/workout_setup/screens/region_screen.dart
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
                    // Session'ı başlat
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
```

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/workout_setup/
git commit -m "feat: add workout setup screens (location, duration, region)"
```

---

## Task 14: Session Provider

**Files:**
- Create: `mobile/lib/features/workout_session/providers/session_provider.dart`
- Test: `mobile/test/providers/session_provider_test.dart`

- [ ] **Step 1: SessionProvider yaz**

```dart
// lib/features/workout_session/providers/session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../auth/providers/auth_provider.dart';

class SessionState {
  final int? sessionId;
  final Exercise? currentExercise;
  final int remainingSeconds;
  final bool completed;
  final WorkoutSummary? summary;

  const SessionState({
    this.sessionId,
    this.currentExercise,
    this.remainingSeconds = 0,
    this.completed = false,
    this.summary,
  });

  SessionState copyWith({
    int? sessionId,
    Exercise? currentExercise,
    int? remainingSeconds,
    bool? completed,
    WorkoutSummary? summary,
  }) =>
      SessionState(
        sessionId: sessionId ?? this.sessionId,
        currentExercise: currentExercise ?? this.currentExercise,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completed: completed ?? this.completed,
        summary: summary ?? this.summary,
      );
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionState>>((ref) {
  return SessionNotifier(ref.read(apiClientProvider));
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionState>> {
  final ApiClient _api;

  SessionNotifier(this._api) : super(const AsyncValue.data(SessionState()));

  Future<void> startSession({
    required String location,
    required int durationMinutes,
    required String region,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/workout/start', data: {
        'location': location,
        'durationMinutes': durationMinutes,
        'region': region,
      });
      final response = WorkoutStartResponse.fromJson(
          res.data as Map<String, dynamic>);
      state = AsyncValue.data(SessionState(
        sessionId: response.sessionId,
        currentExercise: response.exercise,
        remainingSeconds: response.remainingSeconds,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitResult(String result) async {
    final current = state.valueOrNull;
    if (current == null || current.sessionId == null) return;

    try {
      final res = await _api.post(
        '/workout/${current.sessionId}/next',
        data: {
          'exerciseId': current.currentExercise!.id,
          'result': result,
        },
      );
      final response = WorkoutNextResponse.fromJson(
          res.data as Map<String, dynamic>);

      if (response.completed) {
        await _completeSession(current.sessionId!);
      } else {
        state = AsyncValue.data(current.copyWith(
          currentExercise: response.exercise,
          completed: false,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _completeSession(int sessionId) async {
    final res = await _api.post('/workout/$sessionId/complete');
    final summary = WorkoutSummary.fromJson(res.data as Map<String, dynamic>);
    state = AsyncValue.data(SessionState(
      sessionId: sessionId,
      completed: true,
      summary: summary,
    ));
  }

  void tick() {
    state.whenData((s) {
      if (s.remainingSeconds > 0 && !s.completed) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds - 1));
      }
    });
  }

  void reset() => state = const AsyncValue.data(SessionState());
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/features/workout_session/providers/
git commit -m "feat: add session state notifier"
```

---

## Task 15: Exercise Session Ekranı ve Widget'ları

**Files:**
- Create: `mobile/lib/features/workout_session/widgets/lottie_player.dart`
- Create: `mobile/lib/features/workout_session/widgets/session_timer.dart`
- Create: `mobile/lib/features/workout_session/widgets/good_bad_skip_bar.dart`
- Create: `mobile/lib/features/workout_session/screens/exercise_screen.dart`
- Test: `mobile/test/widgets/good_bad_skip_bar_test.dart`

- [ ] **Step 1: LottiePlayer widget yaz**

```dart
// lib/features/workout_session/widgets/lottie_player.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottiePlayer extends StatelessWidget {
  final String assetPath;

  const LottiePlayer({required this.assetPath, super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/$assetPath',
      width: 280,
      height: 280,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.fitness_center,
        size: 120,
        color: Color(0xFF6C63FF),
      ),
    );
  }
}
```

- [ ] **Step 2: SessionTimer widget yaz**

```dart
// lib/features/workout_session/widgets/session_timer.dart
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
        color: AppTheme.primary.withOpacity(0.1),
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
```

- [ ] **Step 3: GoodBadSkipBar failing test yaz**

```dart
// test/widgets/good_bad_skip_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/features/workout_session/widgets/good_bad_skip_bar.dart';

void main() {
  testWidgets('GoodBadSkipBar shows three buttons', (tester) async {
    String? tapped;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GoodBadSkipBar(
              onResult: (r) => tapped = r,
            ),
          ),
        ),
      ),
    );

    expect(find.text('GOOD'), findsOneWidget);
    expect(find.text('BAD'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);

    await tester.tap(find.text('GOOD'));
    expect(tapped, 'GOOD');
  });
}
```

- [ ] **Step 4: Test başarısız olduğunu doğrula**

```bash
cd mobile && flutter test test/widgets/good_bad_skip_bar_test.dart 2>&1 | tail -10
```
Expected: Compilation error (GoodBadSkipBar yok)

- [ ] **Step 5: GoodBadSkipBar implement et**

```dart
// lib/features/workout_session/widgets/good_bad_skip_bar.dart
import 'package:flutter/material.dart';

class GoodBadSkipBar extends StatelessWidget {
  final void Function(String result) onResult;

  const GoodBadSkipBar({required this.onResult, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nasıl gitti?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ResultButton(
                label: 'GOOD',
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFF4CAF50),
                textColor: const Color(0xFF2E7D32),
                onTap: () => onResult('GOOD'),
              ),
              const SizedBox(width: 8),
              _ResultButton(
                label: 'BAD',
                backgroundColor: const Color(0xFFFCE4EC),
                borderColor: const Color(0xFFE91E63),
                textColor: const Color(0xFFC2185B),
                onTap: () => onResult('BAD'),
              ),
              const SizedBox(width: 8),
              _ResultButton(
                label: 'SKIP',
                backgroundColor: const Color(0xFFEDE7F6),
                borderColor: const Color(0xFF9C27B0),
                textColor: const Color(0xFF6A1B9A),
                onTap: () => onResult('SKIP'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label, required this.backgroundColor,
    required this.borderColor, required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Test geçtiğini doğrula**

```bash
flutter test test/widgets/good_bad_skip_bar_test.dart -v
```
Expected: `All tests passed!`

- [ ] **Step 7: ExerciseScreen yaz**

```dart
// lib/features/workout_session/screens/exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/good_bad_skip_bar.dart';
import '../widgets/lottie_player.dart';
import '../widgets/session_timer.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (session) {
        if (session.completed) {
          // Özet ekranına geç
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
            actions: const [Padding(padding: EdgeInsets.only(right: 16), child: SessionTimer())],
          ),
          body: Column(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.1),
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
        );
      },
    );
  }
}
```

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/workout_session/ mobile/test/
git commit -m "feat: add exercise session screen with Lottie, timer, and Good/Bad/Skip"
```

---

## Task 16: Summary Ekranı

**Files:**
- Create: `mobile/lib/features/summary/screens/summary_screen.dart`

- [ ] **Step 1: SummaryScreen yaz**

```dart
// lib/features/summary/screens/summary_screen.dart
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
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/features/summary/
git commit -m "feat: add workout summary screen"
```

---

## Task 17: History ve Profile Ekranları

**Files:**
- Create: `mobile/lib/features/history/screens/history_screen.dart`
- Create: `mobile/lib/features/history/screens/profile_screen.dart`

- [ ] **Step 1: HistoryScreen yaz**

```dart
// lib/features/history/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
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
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
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
                                  ? DateFormat('dd MMM yyyy, HH:mm', 'tr').format(date)
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
```

- [ ] **Step 2: ProfileScreen yaz**

```dart
// lib/features/history/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
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
```

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/features/history/
git commit -m "feat: add history and profile screens"
```

---

## Task 18: Routing ve main.dart

**Files:**
- Create: `mobile/lib/routing/app_router.dart`
- Modify: `mobile/lib/main.dart`

- [ ] **Step 1: AppRouter yaz**

```dart
// lib/routing/app_router.dart
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
```

- [ ] **Step 2: main.dart yaz**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: GymPosesApp()));
}

class GymPosesApp extends StatelessWidget {
  const GymPosesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GymPoses',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 3: Tüm analizleri çalıştır**

```bash
cd mobile && flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 4: Uygulamayı emülatörde çalıştır**

```bash
# Android emülatör açık olmalı
flutter run
```

Test akışı:
1. Login/Register ekranına gelmeli
2. Kayıt ol → `/setup/location` ekranına yönlenmeli
3. Ev seç → Süre seç → Core seç → Backend'e istek gitmiş olmalı → `/session` açılmalı
4. Lottie placeholder dönmeli, sayaç çalışmalı
5. GOOD → sonraki egzersiz gelmeli
6. Süre dolunca → `/summary` açılmalı
7. "Geçmişi Gör" → `/history` açılmalı

- [ ] **Step 5: Final commit**

```bash
git add mobile/lib/main.dart mobile/lib/routing/
git commit -m "feat: add routing and main entry point — Flutter MVP complete"
```

---

## MVP Tamamlandı

Her iki plan birlikte çalışır:
- `backend/` çalışıyor → `mvn spring-boot:run`
- `mobile/` emülatörde → `flutter run`
- PostgreSQL'de `gymposesdb` veritabanı var
- Tüm testler yeşil

Lottie dosyaları için gerçek JSON animasyonları `mobile/assets/lottie/` klasörüne eklenmeli (LottieFiles.com'dan ücretsiz egzersiz animasyonları indirilebilir). Dosya isimleri `DataSeeder`'daki `lottieAssetPath` değerleriyle eşleşmeli.
