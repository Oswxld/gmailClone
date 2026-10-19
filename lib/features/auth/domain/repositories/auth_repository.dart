abstract class AuthRepository {
  Future<void> signIn({
    required String email,
    required String password,
  });

  /// Returns true when registration creates an authenticated session.
  Future<bool> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
