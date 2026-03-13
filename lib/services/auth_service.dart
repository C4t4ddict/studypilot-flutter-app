import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  static User? currentUser() => _client.auth.currentUser;

  static String normalizeLoginId(String idOrEmail) {
    return idOrEmail.trim().toLowerCase();
  }

  static Future<void> signInWithGoogle() async {
    final redirectTo = kIsWeb
        ? '${Uri.base.origin}/auth/callback'
        : 'guiculum://auth/callback';

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  static Future<AuthResponse> signInWithPassword(
      {required String idOrEmail, required String password}) {
    return _client.auth.signInWithPassword(
      email: normalizeLoginId(idOrEmail),
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithPassword(
      {required String idOrEmail, required String password}) {
    return _client.auth.signUp(
      email: normalizeLoginId(idOrEmail),
      password: password,
      data: {'login_id': idOrEmail.trim()},
    );
  }

  static Future<void> ensureAdminAccount() async {
    const adminId = 'admin';
    const adminPw = 'admin';
    try {
      await signInWithPassword(idOrEmail: adminId, password: adminPw);
      return;
    } catch (_) {
      await signUpWithPassword(idOrEmail: adminId, password: adminPw);
      await signInWithPassword(idOrEmail: adminId, password: adminPw);
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
