import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// firebase_auth imported in services; not needed here
import '../../../models/models.dart';
import '../services/auth_service.dart';

/// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider that watches authentication state changes
/// Returns the current UserModel when authenticated, null otherwise
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the current user
/// Returns null if not authenticated
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Auth controller for handling authentication operations
class AuthController extends AsyncNotifier<void> {
  late final AuthService _authService;

  @override
  FutureOr<void> build() {
    _authService = ref.read(authServiceProvider);
    return null;
  }

  /// Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Register a new user
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? companyName,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        companyName: companyName,
        phoneNumber: phoneNumber,
      );
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for auth controller
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  () => AuthController(),
);