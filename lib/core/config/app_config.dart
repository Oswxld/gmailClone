class AppConfig {
  const AppConfig._();

  // Project URL is public. Never add a service_role/secret key to a client.
  static const supabaseUrl = 'https://tspywzqhbrmuwimkvnae.supabase.co';
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSupabase => publishableKey.isNotEmpty;
}
