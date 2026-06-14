import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream<AuthState>.empty();
    }
    return client.auth.onAuthStateChange;
  }

  User? get currentUser => _client?.auth.currentUser;

  /// Envoie un code OTP par email (nécessite config Supabase — voir docs/SUPABASE_AUTH.md).
  Future<void> sendEmailOtp(String email) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    await client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    return client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> updatePassword(String password) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    AuthRepository.validatePassword(password);
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> resetPasswordForEmail(String email) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase non configuré.');
    }
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  static String normalizeEmail(String input) {
    final email = input.trim().toLowerCase();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      throw const AuthException('Adresse email invalide.');
    }
    return email;
  }

  static void validatePassword(String password) {
    if (password.length < 6) {
      throw const AuthException('Le mot de passe doit faire au moins 6 caractères.');
    }
  }
}
