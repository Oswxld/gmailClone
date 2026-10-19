import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../data/repositories/demo_mail_repository.dart';
import '../../data/repositories/supabase_mail_repository.dart';
import '../../domain/models/mail_message.dart';
import '../../domain/repositories/mail_repository.dart';

final mailRepositoryProvider = Provider.autoDispose.family<MailRepository, bool>(
  (ref, isDemo) {
    if (isDemo || !AppConfig.hasSupabase) {
      return DemoMailRepository();
    }
    return SupabaseMailRepository(Supabase.instance.client);
  },
);

final inboxProvider = FutureProvider.autoDispose.family<List<MailMessage>, bool>(
  (ref, isDemo) => ref.watch(mailRepositoryProvider(isDemo)).getInbox(),
);

final avatarLetterProvider = FutureProvider.autoDispose.family<String, bool>(
  (ref, isDemo) => ref.watch(mailRepositoryProvider(isDemo)).getAvatarLetter(),
);
