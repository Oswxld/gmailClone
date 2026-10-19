import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}
