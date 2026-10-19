import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Public, client-side configuration read once from the root .env asset.
/// Do not store Supabase service_role or sb_secret keys in this file.
class AppConfig {
  const AppConfig._();

  static String _supabaseUrl = '';
  static String _publishableKey = '';

  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    _supabaseUrl = (dotenv.maybeGet('SUPABASE_URL') ?? '').trim();
    _publishableKey = (dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ?? '').trim();
  }

  static String get supabaseUrl => _supabaseUrl;
  static String get publishableKey => _publishableKey;

  /// With empty configuration, the app offers guest demo mode.
  static bool get hasSupabase =>
      _supabaseUrl.isNotEmpty && _publishableKey.isNotEmpty;
}
