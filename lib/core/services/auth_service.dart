import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String phone) async {
    final formatted = phone.startsWith('+') ? phone : '+91$phone';
    await _client.auth.signInWithOtp(phone: formatted);
  }

  Future<bool> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    return res.user != null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.s2bazaar://login-callback/',
      authScreenLaunchMode: LaunchMode.inAppWebView,
    );
  }

  /// Removes manual exchange to prevent PKCE state collision
  Future<void> handleDeepLinkCallback(Uri uri) async {
    // Left empty because supabase_flutter handles the deep link exchange automatically
    // The previous implementation collided with Supabase's internal listener, leading to flow_state_not_found
  }
}
