import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ApiClient.instance));

/// App-wide auth state: `loading` during session bootstrap, then either a
/// user or null (guest browsing is allowed — booking is gated).
class AuthState {
  final AppUser? user;
  final bool loading;
  const AuthState({this.user, this.loading = false});

  bool get isLoggedIn => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState(loading: true)) {
    ApiClient.instance.onUnauthorized = logout;
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    final token = await _repo.storedToken();
    if (token == null) {
      state = const AuthState();
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(user: user);
    } catch (_) {
      await _repo.clearToken();
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    final (token, user) = await _repo.login(email, password);
    await _repo.persistToken(token);
    state = AuthState(user: user);
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? gender,
  }) async {
    final (token, user) = await _repo.signup(
        name: name, email: email, password: password, phone: phone, gender: gender);
    await _repo.persistToken(token);
    state = AuthState(user: user);
  }

  /// Phone-OTP login (session established from token + user, like the
  /// web's `applySession`).
  Future<void> applySession(String token, AppUser user) async {
    await _repo.persistToken(token);
    state = AuthState(user: user);
  }

  /// Merge fresh fields after profile / KYC / verification updates.
  void updateUser(AppUser user) => state = AuthState(user: user);

  Future<void> refresh() async {
    if (!state.isLoggedIn) return;
    try {
      state = AuthState(user: await _repo.me());
    } catch (_) {/* keep current user on transient failures */}
  }

  Future<void> logout() async {
    await _repo.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
    (ref) => AuthNotifier(ref.watch(authRepositoryProvider)));
