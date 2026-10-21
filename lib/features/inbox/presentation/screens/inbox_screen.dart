import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../notifications/data/repositories/supabase_push_token_repository.dart';
import '../../../notifications/presentation/services/fcm_push_service.dart';
import '../../../notifications/presentation/services/mail_local_notification_service.dart';
import '../../domain/models/mail_message.dart';
import '../providers/inbox_providers.dart';
import 'email_details_screen.dart';


class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({
    required this.isDemo,
    required this.onSignOut,
    super.key,
  });

  final bool isDemo;
  final VoidCallback onSignOut;
  

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  Timer? _holdTimer;
  Timer? _bannerTimer;
  OverlayEntry? _banner;
  FcmPushService? _pushService;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isDemo) {
      MailLocalNotificationService.pendingMessageId.addListener(
        _handleLocalNotificationTap,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleLocalNotificationTap();
        unawaited(_initializePushNotifications());
      });
    }
  }

  void _handleLocalNotificationTap() {
    if (!mounted || widget.isDemo || _isSigningOut) return;
    final messageId = MailLocalNotificationService.pendingMessageId.value;
    if (messageId == null) return;
    // Consume the stored tap only once. Existing navigation handles the rest.
    MailLocalNotificationService.pendingMessageId.value = null;
    unawaited(_openEmailFromNotification(messageId));
  }

  @override
  void dispose() {
    if (!widget.isDemo) {
      MailLocalNotificationService.pendingMessageId.removeListener(
        _handleLocalNotificationTap,
      );
    }
    _holdTimer?.cancel();
    _bannerTimer?.cancel();
    _removeBanner();
    // Detach the listeners when leaving the inbox; explicit sign-out
    // separately removes the installation from Supabase.
    final pushService = _pushService;
    if (pushService != null && !_isSigningOut) {
      unawaited(pushService.stop(unregister: false));
    }
    super.dispose();
  }

  void _removeBanner() {
    _banner?.remove();
    _banner?.dispose();
    _banner = null;
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    _isSigningOut = true;
    if (!widget.isDemo) {
      try {
        await _pushService?.stop();
      } catch (error) {
        debugPrint('FCM cleanup failed: $error');
      }
    }
    if (mounted) widget.onSignOut();
  }

  Future<void> _initializePushNotifications() async {
    if (widget.isDemo || _isSigningOut) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    final pushService = FcmPushService(
      tokens: SupabasePushTokenRepository(client),


      onMessageOpened: (messageId) {
  debugPrint('Notification opened: $messageId');

  unawaited(
    _openEmailFromNotification(messageId),
  );
},
     onForegroundMessage: (messageId) {
  unawaited(
    _handleForegroundNotification(messageId),
  );
},
    );
    _pushService = pushService;

    try {
      final registered = await pushService.start();
      debugPrint('FCM registration started: $registered');
      // If the screen was left while registration was pending,
      // clean up the listeners rather than leaving them attached.
      if (!mounted && !_isSigningOut) {
        await pushService.stop(unregister: false);
      }
    } catch (error) {
      debugPrint('FCM registration failed: $error');
    }
  }
Future<void> _openEmailFromNotification(
  String messageId,
) async {
  if (!mounted || widget.isDemo || _isSigningOut) {
    return;
  }

  debugPrint(
    'Opening email from notification: $messageId',
  );

  try {
    // Retrieve the message from Supabase.
    final message = await _getMessageById(messageId);

    // Authentication or the screen may have changed.
    if (!mounted || _isSigningOut) return;

    if (message == null) {
      debugPrint(
        'Notification email not found: $messageId',
      );
      return;
    }

    // Refresh the inbox.
    ref.invalidate(inboxProvider(false));

    // Wait until Flutter completes its current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isSigningOut) return;

      _openEmail(message);
    });

  } catch (error) {
    debugPrint(
      'Failed to open notification email: $error',
    );
  }
}
Future<MailMessage?> _getMessageById(String messageId) async {
  final repository = ref.read(
    mailRepositoryProvider(false),
  );

  final messages = await repository.getInbox();

  for (final message in messages) {
    if (message.id == messageId) {
      return message;
    }
  }

  return null;
}


Future<void> _handleForegroundNotification(
  String messageId,
) async {
  if (!mounted || widget.isDemo || _isSigningOut) {
    return;
  }

  debugPrint('FCM foreground message: $messageId');

  // Refresh the inbox so the latest email appears.
  ref.invalidate(inboxProvider(false));

  try {
    // Retrieve the actual message.
    final message = await _getMessageById(messageId);

    // The screen might have been disposed while awaiting.
    if (!mounted || _isSigningOut) return;

    if (message == null) {
      debugPrint(
        'Foreground notification email not found: $messageId',
      );
      return;
    }

    // Display our existing clickable notification banner.
    _showDemoNotification(message);

  } catch (error) {
    debugPrint(
      'Failed to handle foreground notification: $error',
    );
  }
}

  void _openEmail(MailMessage message) {
    _removeBanner();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmailDetailsScreen(message: message),
      ),
    );
    if (!message.isRead) {
      ref.read(mailRepositoryProvider(widget.isDemo))
          .markRead(message.id)
          .then((_) {
            if (mounted) ref.invalidate(inboxProvider(widget.isDemo));
          }).catchError((Object _) {
            // Keep the reading experience available if an update fails.
          });
    }
  }

  void _showDemoNotification(MailMessage message) {
    _bannerTimer?.cancel();
    _removeBanner();
    final overlay = Overlay.of(context);
    _banner = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: 12,
        right: 12,
        top: MediaQuery.paddingOf(overlayContext).top + 8,
        child: Material(
          color: const Color(0xFFF1F5FA),
          elevation: 10,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openEmail(message),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined,
                          color: AppPalette.blue, size: 19),
                      SizedBox(width: 7),
                      Expanded(child: Text('Mail Demo • Test notification',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700))),
                      Text('now', style: TextStyle(
                          fontSize: 12, color: AppPalette.muted)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(message.subject, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(message.preview, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppPalette.muted)),
                  const SizedBox(height: 5),
                  const Text('Tap to open this simulated message',
                      style: TextStyle(
                          fontSize: 11, color: AppPalette.blue)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_banner!);
    _bannerTimer = Timer(const Duration(seconds: 8), _removeBanner);
  }

  Future<void> _setLetter(String raw) async {
    final letter = raw.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(letter)) return;
    await ref.read(mailRepositoryProvider(widget.isDemo))
        .setAvatarLetter(letter);
    if (mounted) ref.invalidate(avatarLetterProvider(widget.isDemo));
  }

  Future<void> _sendTestMessage() async {
    try {
      final message = await ref.read(mailRepositoryProvider(widget.isDemo))
          .generateTestMessage();
      if (!mounted) return;
      ref.invalidate(inboxProvider(widget.isDemo));
      _showDemoNotification(message);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to create the test notification.'),
        ));
      }
    }
  }

  Future<void> _openMasterControls() async {
    _holdTimer?.cancel();
    final current = ref.read(avatarLetterProvider(widget.isDemo))
        .asData?.value ?? 'O';
    final controller = TextEditingController(text: current);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.viewInsetsOf(sheetContext).bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Developer controls',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
            const SizedBox(height: 5),
            const Text('GMail settings .',
              style: TextStyle(color: AppPalette.muted)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: false,
              maxLength: 1,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Avatar letter (A–Z)',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim().toUpperCase();
                if (!RegExp(r'^[A-Z]$').hasMatch(value)) return;
                try {
                  await _setLetter(value);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                } catch (_) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to save avatar settings.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save avatar letter'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Generate a test notification'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _sendTestMessage();
              },
            ),
            const Divider(height: 32),
            TextButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_signOut());
              },
              icon: const Icon(Icons.logout),
              label: Text(widget.isDemo ? 'Sign Out' : 'Sign out'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Widget _accountAvatar() {
    final letter = ref.watch(avatarLetterProvider(widget.isDemo))
        .asData?.value ?? 'O';
    return Semantics(
      label: 'Account avatar. Hold three seconds for demo controls.',
      child: Listener(
        onPointerDown: (_) {
          _holdTimer?.cancel();
          _holdTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) _openMasterControls();
          });
        },
        onPointerUp: (_) => _holdTimer?.cancel(),
        onPointerCancel: (_) => _holdTimer?.cancel(),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppPalette.purple,
          child: Text(letter, style: const TextStyle(
            fontSize: 16, color: Colors.white,
            fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emails = ref.watch(inboxProvider(widget.isDemo));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 12,
        automaticallyImplyLeading: false,
        title: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
          decoration: BoxDecoration(
            color: AppPalette.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Color(0x15000000), blurRadius: 3,
                  offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.menu, size: 25,
                  color: AppPalette.text),
              const SizedBox(width: 18),
              const Expanded(
                child: Text('Search in emails',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400,
                    color: AppPalette.muted)),
              ),
              _accountAvatar(),
            ],
          ),
        ),
      ),
      body: emails.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load the demo inbox.'),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppPalette.muted, fontSize: 12)),
                TextButton(
                  onPressed: () => ref.invalidate(inboxProvider(widget.isDemo)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (messages) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inboxProvider(widget.isDemo));
            await ref.read(inboxProvider(widget.isDemo).future);
          },
          child: ListView(
            key: const PageStorageKey('mail-inbox-scroll'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Primary',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(widget.isDemo ? 'DEMO' : '',
                      style: const TextStyle(
                        color: AppPalette.outline,
                        fontSize: 10, letterSpacing: 1.1,
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _categoryCard(
                icon: Icons.label_rounded,
                color: const Color(0xFF1E8E3E),
                title: 'Promotions',
                preview: 'Design Weekly — Weekly highlights...',
                count: '10 new',
                badge: const Color(0xFFC4EED0),
              ),
              _categoryCard(
                icon: Icons.group_rounded,
                color: const Color(0xFF1A73E8),
                title: 'Social',
                preview: 'Community — Recent activity...',
                count: '5 new',
                badge: const Color(0xFFD3E3FD),
              ),
              for (final message in messages) ...[
                if (message.demoKey == 'project')
                  _categoryCard(
                    icon: Icons.info,
                    color: const Color(0xFFE8710A),
                    title: 'Updates',
                    preview: 'Product Notes — Latest news...',
                    count: '16 new',
                    badge: const Color(0xFFFEEBD9),
                  ),
                _messageTile(message),
              ],
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'compose',
        onPressed: () {},
        backgroundColor: const Color(0xFFD3E3FD),
        foregroundColor: const Color(0xFF001D35),
        icon: const Icon(Icons.edit_outlined, size: 23),
        label: const Text('Compose', style: TextStyle(
          fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: const Color(0xFFF0EDED),
        indicatorColor: const Color(0xFFD3E3FD),
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Mail',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            label: 'Meet',
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String preview,
    required String count,
    required Color badge,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(width: 36, height: 36,
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(preview, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: badge, borderRadius: BorderRadius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              child: Text(count, style: TextStyle(
                color: color, fontWeight: FontWeight.w700,
                fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageTile(MailMessage message) {
    final unread = !message.isRead;
    return InkWell(
      onTap: () => _openEmail(message),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 15, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _color(message.avatarColor),
              child: Text(message.avatarLetter,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(message.senderName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15,
                            fontWeight: unread
                                ? FontWeight.w700 : FontWeight.w400))),
                      const SizedBox(width: 6),
                      Text(_time(message.receivedAt), style: TextStyle(
                        fontSize: 12, fontWeight: unread
                            ? FontWeight.w700 : FontWeight.w400,
                        color: unread ? AppPalette.text : AppPalette.muted)),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        const CircleAvatar(radius: 4,
                            backgroundColor: AppPalette.text),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(message.subject,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14, fontWeight: unread
                        ? FontWeight.w700 : FontWeight.w400)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(child: Text(message.preview,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13, color: AppPalette.muted))),
                      const SizedBox(width: 6),
                      Icon(message.isStarred
                        ? Icons.star : Icons.star_border,
                        size: 20, color: message.isStarred
                            ? const Color(0xFFF4B400) : AppPalette.outline),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final n = int.tryParse(cleaned, radix: 16);
    return n == null ? AppPalette.blue : Color(0xFF000000 | n);
  }

  String _time(DateTime when) {
    final now = DateTime.now();
    if (now.year == when.year &&
        now.month == when.month && now.day == when.day) {
      final h = when.hour.toString().padLeft(2, '0');
      final m = when.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${when.day} ${months[when.month - 1]}';
  }
}
