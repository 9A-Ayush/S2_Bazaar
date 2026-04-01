// ─── Supabase Config Example ──────────────────────────────────────────────────
// Copy this file to supabase_config.dart and fill in your keys,
// OR use --dart-define-from-file=.env (recommended).
//
// DO NOT commit supabase_config.dart — it is gitignored.
abstract class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
