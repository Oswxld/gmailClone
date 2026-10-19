import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/push_token_repository.dart';

class SupabasePushTokenRepository implements PushTokenRepository {
  const SupabasePushTokenRepository(this.client);

  final SupabaseClient client;

  String get _ownerId {
    final ownerId = client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Sign in before registering for push notifications.');
    }
    return ownerId;
  }

  @override
  Future<void> registerToken(String token) async {
    // The token identifies an app installation, not an email address.
    // Each account can own multiple registered Android devices.
    await client.from('g_device_tokens').upsert({
      'owner_id': _ownerId,
      'fcm_target': token,
      'platform': 'android',
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fcm_target');
  }

  @override
  Future<void> unregisterToken(String token) async {
    await client.from('g_device_tokens')
        .delete()
        .eq('owner_id', _ownerId)
        .eq('fcm_target', token);
  }
}
