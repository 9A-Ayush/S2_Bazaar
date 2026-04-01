// ─── Supabase Config ──────────────────────────────────────────────────────────
// Keys are injected at build time via --dart-define.
// Run with:
//   flutter run --dart-define-from-file=.env
// Or set them individually:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}



