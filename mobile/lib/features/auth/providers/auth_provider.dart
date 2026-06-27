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
