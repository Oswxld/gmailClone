import 'package:flutter_test/flutter_test.dart';
import 'package:gmail_clone/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Supabase client configuration from the root .env asset', () async {
    await AppConfig.load();

    expect(AppConfig.supabaseUrl, startsWith('https://'));
    // A blank key is valid for guest mode; a real publishable key
    // may be supplied by the developer's ignored local .env.
    expect(AppConfig.hasSupabase, AppConfig.publishableKey.isNotEmpty);
  });
}
