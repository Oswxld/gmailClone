import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Creates Android system notifications from background FCM data messages.
///
/// The small status-bar icon is monochrome on Android. The large sender avatar
/// remains a full-color bitmap (subject to the device's notification layout).
class MailLocalNotificationService {
  MailLocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Taps received before login/inbox initialization remain available.
  static final ValueNotifier<String?> pendingMessageId =
      ValueNotifier<String?>(null);

  static const InitializationSettings _settings = InitializationSettings(
    android: AndroidInitializationSettings('ic_notification'),
  );

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await _plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: (response) {
        _rememberTap(response.payload);
      },
    );

    final launched = await _plugin.getNotificationAppLaunchDetails();
    if (launched?.didNotificationLaunchApp == true) {
      _rememberTap(launched?.notificationResponse?.payload);
    }
  }

  static void _rememberTap(String? messageId) {
    if (messageId == null || !_uuid.hasMatch(messageId)) return;
    pendingMessageId.value = messageId;
  }

  /// Called exclusively from the Android FCM background isolate.
  /// Foreground banners and FCM registration remain unchanged.
  static Future<void> showBackground(RemoteMessage remote) async {
    if (remote.data['type'] != 'demo_mail') return;
    final messageId = remote.data['message_id'];
    if (messageId == null || !_uuid.hasMatch(messageId)) return;

    // The background isolate has a separate copy of Dart static state.
    await _plugin.initialize(settings: _settings);

    final sender = _text(remote.data['sender'], 'Gmail Clone', 80);
    final subject = _text(remote.data['subject'], '', 130);
    final preview = _text(remote.data['preview'], 'New email', 180);
    final body = subject.isEmpty ? preview : '$subject\n$preview';

    const senderImage = DrawableResourceAndroidBitmap('sender_avatar');
    final androidDetails = AndroidNotificationDetails(
      'gmail_clone_messages',
      'Email notifications',
      channelDescription: 'New messages in Gmail Clone',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: senderImage,
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
    );

    await _plugin.show(
      id: _notificationId(messageId),
      title: sender,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: messageId,
    );
  }

  static String _text(String? value, String fallback, int limit) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed.length <= limit ? trimmed : trimmed.substring(0, limit);
  }

  static int _notificationId(String messageId) {
    // Stable between Dart isolates: repeated delivery updates the same email
    // notification instead of creating an extra notification.
    var hash = 0;
    for (final unit in messageId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
