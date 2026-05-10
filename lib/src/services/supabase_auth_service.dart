import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

class SupabaseAuthService {
  bool get isReady =>
      AppConfig.hasSupabase && RuntimeFlags.supabaseInitialized;

  GoTrueClient? get _auth => isReady ? Supabase.instance.client.auth : null;

  Session? get currentSession => _auth?.currentSession;
  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState>? authStateChanges() => _auth?.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw const AuthException(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to .env.',
      );
    }
    final response = await auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null && name.isNotEmpty) 'full_name': name,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw const AuthException(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to .env.',
      );
    }
    return auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
