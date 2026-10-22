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

  // Previous versions seeded these 13 generic examples under these keys.
  // Pair by index with buildExampleMessages() to replace *only* known legacy
  // fixtures while preserving their id, is_read, and is_starred state.
  static const legacySeedKeys = <String, String>{
    'studio': 'Studio Updates',
    'project': 'Project Updates',
    'trading-news': 'Trading Demo',
    'workspace': 'Workspace Team',
    'account': 'Account Demo',
    'design': 'Design Weekly',
    'community': 'Community',
    'storage': 'Cloud Drive',
    'calendar': 'Calendar',
    'newsletter': 'Product Notes',
    'learning': 'Course Team',
    'delivery': 'Delivery Demo',
    'welcome': 'Mail Demo',
  };

  Future<void> _seed() async {
    final templates = buildExampleMessages();

    // Determine which fixtures already exist for this user.
    final allKeys = <String>[
      ...legacySeedKeys.keys,
      ...templates.map((message) => message.demoKey!).toList(),
    ];
    final existingRows = await client
        .from('g_messages')
        .select('demo_key,sender_name')
        .eq('owner_id', _userId)
        .inFilter('demo_key', allKeys);

    final knownByKey = <String, String>{};
    for (final row in existingRows) {
      final key = row['demo_key'] as String?;
      final sender = row['sender_name'] as String?;
      if (key != null && sender != null) knownByKey[key] = sender;
    }

    // One-time, per-user migration of the earlier example messages. No
    // deletion of other mail and no modification of real/unseeded messages.
    // These are UPDATEs rather than INSERTs, so our INSERT-only notification
    // webhook is not triggered for the 13 already-existing examples.
    final oldKeys = legacySeedKeys.keys.toList();
    for (var i = 0; i < templates.length; i++) {
      final template = templates[i];
      final newKey = template.demoKey!;
      if (knownByKey.containsKey(newKey)) continue;

      final oldKey = oldKeys[i];
      final oldSender = legacySeedKeys[oldKey]!;
      if (knownByKey[oldKey] != oldSender) continue;

      final changes = template.toSeedRow(_userId)
        ..remove('owner_id')
        ..remove('is_read');

      await client
          .from('g_messages')
          .update(changes)
          .eq('owner_id', _userId)
          .eq('demo_key', oldKey)
          .eq('sender_name', oldSender);

      knownByKey.remove(oldKey);
      knownByKey[newKey] = template.senderName;
    }

    final missing = templates
        .where((message) => !knownByKey.containsKey(message.demoKey))
        .map((message) => message.toSeedRow(_userId))
        .toList();

    if (missing.isNotEmpty) {
      await client.from('g_messages').upsert(
        missing,
        onConflict: 'owner_id,demo_key',
        ignoreDuplicates: true,
      );
    }
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
