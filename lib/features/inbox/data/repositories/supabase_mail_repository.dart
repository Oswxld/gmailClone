import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/mail_message.dart';
import '../../domain/repositories/mail_repository.dart';
import 'demo_mail_repository.dart';

class SupabaseMailRepository implements MailRepository {
  const SupabaseMailRepository(this.client);

  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('You must sign in to view this inbox.');
    return id;
  }

  Future<void> _seed() async {
    final rows = buildExampleMessages()
        .map((message) => message.toSeedRow(_userId))
        .toList();
    await client.from('g_messages').upsert(
      rows,
      onConflict: 'owner_id,demo_key',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<List<MailMessage>> getInbox() async {
    await _seed();
    final rows = await client.from('g_messages')
        .select()
        .eq('owner_id', _userId)
        .order('received_at', ascending: false);
    return (rows as List)
        .map((row) => MailMessage.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markRead(String messageId) async {
    await client.from('g_messages').update({'is_read': true})
        .eq('owner_id', _userId).eq('id', messageId);
  }

  @override
  Future<void> setStar(String messageId, bool starred) async {
    await client.from('g_messages').update({'is_starred': starred})
        .eq('owner_id', _userId).eq('id', messageId);
  }

  @override
  Future<String> getAvatarLetter() async {
    final row = await client.from('g_user_settings')
        .select('avatar_letter').eq('user_id', _userId).maybeSingle();
    return row?['avatar_letter'] as String? ?? 'O';
  }

  @override
  Future<void> setAvatarLetter(String letter) async {
    await client.from('g_user_settings').upsert({
      'user_id': _userId,
      'avatar_letter': letter,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<MailMessage> generateTestMessage() async {
    final row = await client.from('g_messages').insert({
      'owner_id': _userId,
      'sender_name': 'Trading Demo',
      'sender_address': 'alerts@example.test',
      'subject': 'Demo verification code: 123456',
      'preview': 'A test message, not a real account verification.',
      'body': 'This demonstration code is 123456. It cannot authorize any real transaction.',
      'avatar_letter': 'T',
      'avatar_color': '#FF444F',
      'kind': 'demo_code',
    }).select().single();
    final message = MailMessage.fromRow(row);
    await client.from('g_notifications').insert({
      'owner_id': _userId,
      'message_id': message.id,
      'title': 'Demo: New verification example',
      'body': message.subject,
    });
    return message;
  }
}
