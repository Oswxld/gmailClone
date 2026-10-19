/// Device registrations for the signed-in Mail Demo account.
///
/// The domain layer stays independent from Firebase and Supabase.
abstract class PushTokenRepository {
  Future<void> registerToken(String token);
  Future<void> unregisterToken(String token);
}
