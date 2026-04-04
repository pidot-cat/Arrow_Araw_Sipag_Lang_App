import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_stats_model.dart';

/// All Supabase interactions are centralised here.
/// Tables required:
///   game_stats (user_id uuid PK/FK, total_wins int, total_losses int,
///               total_matches int, total_days int, updated_at timestamptz)
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Step 1 (Signup): Creates a user with email and password.
  /// This will send a confirmation email/OTP if "Confirm Email" is enabled in Supabase.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  /// Step 2 (Signup/Login): Verifies the OTP sent to email.
  /// type can be OtpType.signup, OtpType.recovery, or OtpType.email.
  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  /// Resends the OTP for a specific type.
  static Future<void> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    await _client.auth.resend(
      email: email,
      type: type,
    );
  }

  /// Login with email and password.
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  /// Sends a password reset email.
  static Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Updates the password of the currently authenticated user.
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Permanently deletes the current user's account via a Supabase SQL function.
  /// REQUIREMENT: You must create the SQL function in Supabase first — see README below.
  static Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
  }

  // ── Game Stats ───────────────────────────────────────────────────────────

  static Future<void> saveGameStats(GameStatsModel stats) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('game_stats').upsert(
      {
        'user_id': user.id,
        'total_wins': stats.totalWins,
        'total_losses': stats.totalLosses,
        'total_matches': stats.totalMatches,
        'total_days': stats.totalDays,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  static Future<GameStatsModel?> fetchGameStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('game_stats')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return GameStatsModel(
      totalWins: (response['total_wins'] as int?) ?? 0,
      totalLosses: (response['total_losses'] as int?) ?? 0,
      totalMatches: (response['total_matches'] as int?) ?? 0,
      totalDays: (response['total_days'] as int?) ?? 1,
    );
  }
}
