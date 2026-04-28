import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial());

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      state = AuthState.authenticated(result);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> registerTechnician({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bio,
    required List<String> specialties,
    required List<String> documents,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.registerTechnician(
        name: name,
        email: email,
        phone: phone,
        password: password,
        bio: bio,
        specialties: specialties,
        documents: documents,
      );
      state = AuthState.authenticated(result);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(result);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> loginTechnician({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.loginTechnician(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(result);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> getTechnicianVerificationStatus() async {
    try {
      return await _authRepository.getTechnicianVerificationStatus();
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  Future<void> uploadTechnicianDocuments(List<String> documents) async {
    try {
      await _authRepository.uploadTechnicianDocuments(documents);
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        state = const AuthState.authenticated({});
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = const AuthState.initial();
    }
  }
}

sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(Map<String, dynamic> user) =
      _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

class _Initial extends AuthState {
  const _Initial();
}

class _Loading extends AuthState {
  const _Loading();
}

class _Authenticated extends AuthState {
  final Map<String, dynamic> user;

  const _Authenticated(this.user);
}

class _Error extends AuthState {
  final String message;

  const _Error(this.message);
}
