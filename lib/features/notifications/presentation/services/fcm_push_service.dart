import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/repositories/push_token_repository.dart';

/// Android push adapter for Firebase Messaging 17+.
///
/// The caller must first initialize Firebase using the generated
/// `lib/firebase_options.dart` before calling [start].
/// A signed-in Supabase user is required for registration.
class FcmPushService {
  FcmPushService({
    required this.tokens,
    required this.onMessageOpened,
    required this.onForegroundMessage,
    FirebaseMessaging? firebaseMessaging,
  }) : _messaging = firebaseMessaging ?? FirebaseMessaging.instance;

  final PushTokenRepository tokens;
  final void Function(String messageId) onMessageOpened;
  final void Function(String messageId) onForegroundMessage;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _registered;
  StreamSubscription<String>? _unregistered;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _foreground;
  String? _installationId;
  bool _started = false;

  Future<bool> start() async {
    if (_started) return true;
    debugPrint('&&&&&&&&&& FCM: STARTING PUSH LISTENERS &&&&&&&&&&');
    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('&&&&&&&&&& FCM PERMISSION: ${permission.authorizationStatus} &&&&&&&&&&');
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }

    // FCM 17 uses Firebase Installation IDs (FIDs) for send targeting.
    // Listen *before* register() so the first registration is not missed.
    _registered = _messaging.onRegistered.listen((installationId) {
      debugPrint('&&&&&&&&&& FCM REGISTRATION EVENT RECEIVED &&&&&&&&&&');
      _installationId = installationId;
      unawaited(_saveRegistration(installationId));
    });
    _unregistered = _messaging.onUnregistered.listen((installationId) {
      debugPrint('&&&&&&&&&& FCM UNREGISTERED EVENT RECEIVED &&&&&&&&&&');
      unawaited(_removeRegistration(installationId));
    });

    _opened = FirebaseMessaging.onMessageOpenedApp.listen((remote) {
      debugPrint('&&&&&&&&&& FCM MESSAGE OPENED FROM NOTIFICATION &&&&&&&&&&');
      final id = _validMessageId(remote);
      if (id != null) onMessageOpened(id);
    }, onError: (Object error) {
      debugPrint('&&&&&&&&&& FCM OPENED LISTENER ERROR: $error &&&&&&&&&&');
    });

    _foreground = FirebaseMessaging.onMessage.listen((remote) {
      debugPrint('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
      debugPrint('&&&&&&&&&& MESSAGE RECEIVED - FOREGROUND &&&&&&&&&&');
      debugPrint('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
      debugPrint('FCM payload type: ${remote.data['type'] ?? 'missing'}');
      final id = _validMessageId(remote);
      if (id != null) {
        debugPrint('&&&&&&&&&& MESSAGE VALID - FORWARDING TO INBOX &&&&&&&&&&');
        onForegroundMessage(id);
      } else {
        debugPrint('&&&&&&&&&& MESSAGE RECEIVED BUT INVALID PAYLOAD &&&&&&&&&&');
      }
    }, onError: (Object error) {
      debugPrint('&&&&&&&&&& FCM FOREGROUND LISTENER ERROR: $error &&&&&&&&&&');
    });
    
    _started = true;
    debugPrint('&&&&&&&&&& FCM LISTENERS ATTACHED; REGISTERING &&&&&&&&&&');
    await _messaging.register();
    debugPrint('&&&&&&&&&& FCM REGISTER CALL COMPLETED &&&&&&&&&&');

    // Covers a notification that opened a terminated Android application.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('&&&&&&&&&& MESSAGE RECEIVED - APP LAUNCH &&&&&&&&&&');
      final id = _validMessageId(initial);
      if (id != null) onMessageOpened(id);
    }
    return true;
  }

  Future<void> _saveRegistration(String fid) async {
    try {
      await tokens.registerToken(fid);
      debugPrint('&&&&&&&&&& FCM REGISTRATION SAVED TO SUPABASE &&&&&&&&&&');
    } catch (error) {
      debugPrint('&&&&&&&&&& FCM REGISTRATION SAVE FAILED: $error &&&&&&&&&&');
    }
  }

  Future<void> _removeRegistration(String fid) async {
    try {
      await tokens.unregisterToken(fid);
    } catch (_) {
      // Cleanup can be retried on the next authenticated session.
    }
  }

  String? _validMessageId(RemoteMessage message) {
    if (message.data['type'] != 'demo_mail') return null;
    final id = message.data['message_id'];
    if (id == null) return null;
    final uuid = RegExp(
      r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
      r'[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
    );
    return uuid.hasMatch(id) ? id : null;
  }

  /// Call before Supabase signOut, so RLS still permits token cleanup.
  Future<void> stop({bool unregister = true}) async {
    if (_started && unregister && _installationId != null) {
      await _removeRegistration(_installationId!);
      await _messaging.unregister();
    }
    await _registered?.cancel();
    await _unregistered?.cancel();
    await _opened?.cancel();
    await _foreground?.cancel();
    _registered = null;
    _unregistered = null;
    _opened = null;
    _foreground = null;
    _installationId = null;
    _started = false;
  }
}
