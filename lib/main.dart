import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/inbox/presentation/screens/inbox_screen.dart';
import 'features/notifications/presentation/services/mail_background_handler.dart';
import 'features/notifications/presentation/services/mail_local_notification_service.dart';


//firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FirebaseMessaging.onBackgroundMessage(mailBackgroundHandler);
    await MailLocalNotificationService.initialize();
  }

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.publishableKey,
    );
  }

  runApp(const ProviderScope(child: MailDemoApp()));
}

class MailDemoApp extends StatefulWidget {
  const MailDemoApp({super.key});

  @override
  State<MailDemoApp> createState() => _MailDemoAppState();
}

class _MailDemoAppState extends State<MailDemoApp> {
  bool demoSession = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _home(),
    );
  }

  Widget _home() {
    if (demoSession) {
      return InboxScreen(
        isDemo: true,
        onSignOut: () => setState(() => demoSession = false),
      );
    }

    if (!AppConfig.hasSupabase) {
      return LoginScreen(
        configured: false,
        onDemo: () => setState(() => demoSession = true),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final signedIn = Supabase.instance.client.auth.currentUser != null;
        if (!signedIn) {
          return LoginScreen(
            configured: true,
            onDemo: () => setState(() => demoSession = true),
          );
        }
        return InboxScreen(
          isDemo: false,
          onSignOut: () async {
            await Supabase.instance.client.auth.signOut();
          },
        );
      },
    );
  }
}
