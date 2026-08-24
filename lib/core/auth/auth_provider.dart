import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

class AuthState {
  final bool isLoggedIn;
  final String? role;
  final String? name;

  const AuthState({this.isLoggedIn = false, this.role, this.name});

  bool get isAdmin      => role == 'admin';
  bool get isExecutive  => role == 'executive';
  bool get canViewAll   => role == 'admin' || role == 'executive';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  AuthNotifier(this._service) : super(const AuthState());

  Future<void> init() async {
    final loggedIn = await _service.isLoggedIn();
    if (loggedIn) {
      state = AuthState(
        isLoggedIn: true,
        role: await _service.getRole(),
        name: await _service.getName(),
      );
    }
  }

  Future<void> login(String username, String password) async {
    final data = await _service.login(username, password);
    state = AuthState(
      isLoggedIn: true,
      role: data['role'],
      name: data['name'],
    );
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}

final authServiceProvider = Provider((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
