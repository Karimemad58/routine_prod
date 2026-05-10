import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration sourced from `.env` first, falling back to
/// `--dart-define=` runtime values, then sensible defaults.
class AppConfig {
  static String _read(String key, {String defaultValue = ''}) {
    final fromEnv = dotenv.maybeGet(key);
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return defaultValue;
  }

  static String get supabaseUrl => _read(
        'SUPABASE_URL',
        defaultValue: const String.fromEnvironment('SUPABASE_URL'),
      );

  static String get supabaseAnonKey => _read(
        'SUPABASE_ANON_KEY',
        defaultValue: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class RuntimeFlags {
  static bool supabaseInitialized = false;
  static bool dotenvLoaded = false;
}
