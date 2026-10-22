import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_options.dart';
import 'mail_local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> mailBackgroundHandler(RemoteMessage message) async {
  debugPrint('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
  debugPrint('&&&&&&&&&& MESSAGE RECEIVED - BACKGROUND &&&&&&&&&&');
  debugPrint('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MailLocalNotificationService.showBackground(message);
    debugPrint('&&&&&&&&&& FCM BACKGROUND HANDLER COMPLETED &&&&&&&&&&');
  } catch (error) {
    debugPrint('&&&&&&&&&& FCM BACKGROUND HANDLER FAILED: $error &&&&&&&&&&');
    rethrow;
  }
}
