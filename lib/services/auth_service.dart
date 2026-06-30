import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalUser {
  final String id;
  final String email;
  const LocalUser({required this.id, required this.email});
}

class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static final _authStateController = StreamController<AuthState>.broadcast();
  static const _demoModeKey = 'demo_mode_enabled';
  static const _demoUserKey = 'demo_user_email';
  static LocalUser? _demoUser;
  static bool _demoMode = false;

  static bool get isDemoMode => _demoMode;

  static Future<void> configureDemoMode(bool enabled) async {
    _demoMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModeKey, enabled);
    if (enabled) {
      final savedEmail = prefs.getString(_demoUserKey);
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _demoUser = LocalUser(id: 'demo-user', email: savedEmail);
      }
    }
  }

  static Future<void> restoreDemoSessionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    _demoMode = prefs.getBool(_demoModeKey) ?? _demoMode;
    if (_demoMode) {
      final savedEmail = prefs.getString(_demoUserKey);
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _demoUser = LocalUser(id: 'demo-user', email: savedEmail);
      }
    }
  }

  static Stream<AuthState> authStateChanges() {
    if (_demoMode) return _authStateController.stream;
    return _client.auth.onAuthStateChange;
  }

  static dynamic currentUser() => _demoMode ? _demoUser : _client.auth.currentUser;

  static String normalizeLoginId(String idOrEmail) {
    final v = idOrEmail.trim();
    if (v.contains('@')) return v;
    return '$v@study-pilot.local';
  }

  static Future<void> signInWithGoogle() async {
    if (_demoMode) {
      throw Exception('데모 모드에서는 Google 로그인을 지원하지 않아. 관리자 빠른 시작을 눌러줘.');
    }
    final redirectTo = kIsWeb ? '${Uri.base.origin}/auth/callback' : 'study-pilot://auth/callback';

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  static Future<AuthResponse?> signInWithPassword({required String idOrEmail, required String password}) async {
    if (_demoMode) {
      final email = normalizeLoginId(idOrEmail);
      if (password.trim().isEmpty) throw Exception('비밀번호를 입력해줘.');
      final prefs = await SharedPreferences.getInstance();
      _demoUser = LocalUser(id: 'demo-user', email: email);
      await prefs.setString(_demoUserKey, email);
      _authStateController.add(AuthState(AuthChangeEvent.signedIn, null));
      return null;
    }
    return _client.auth.signInWithPassword(
      email: normalizeLoginId(idOrEmail),
      password: password,
    );
  }

  static Future<AuthResponse?> signUpWithPassword({required String idOrEmail, required String password}) async {
    if (_demoMode) {
      return signInWithPassword(idOrEmail: idOrEmail, password: password);
    }
    return _client.auth.signUp(
      email: normalizeLoginId(idOrEmail),
      password: password,
      data: {'login_id': idOrEmail.trim()},
    );
  }

  static Future<void> ensureAdminAccount() async {
    const adminId = 'admin';
    const adminPw = 'admin';
    if (_demoMode) {
      await signInWithPassword(idOrEmail: adminId, password: adminPw);
      return;
    }
    try {
      await signInWithPassword(idOrEmail: adminId, password: adminPw);
      return;
    } catch (_) {
      await signUpWithPassword(idOrEmail: adminId, password: adminPw);
      await signInWithPassword(idOrEmail: adminId, password: adminPw);
    }
  }

  static Future<void> signOut() async {
    if (_demoMode) {
      final prefs = await SharedPreferences.getInstance();
      _demoUser = null;
      await prefs.remove(_demoUserKey);
      _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
      return;
    }
    await _client.auth.signOut();
  }
}
