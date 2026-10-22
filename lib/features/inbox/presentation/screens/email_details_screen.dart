import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/mail_message.dart';
import '../widgets/mail_sender_avatar.dart';

class EmailDetailsScreen extends StatelessWidget {
  const EmailDetailsScreen({required this.message, super.key});

  final MailMessage message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to inbox',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Archive (display only)',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Delete (display only)',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Mark as unread (display only)',
            icon: const Icon(Icons.mark_email_unread_outlined),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'More (display only)',
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.subject,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Icon(
                  Icons.star_border,
                  size: 25,
                  color: AppPalette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppPalette.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                child: Text(
                  'Inbox',
                  style: TextStyle(fontSize: 11, color: AppPalette.muted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          Row(
            children: [
              MailSenderAvatar(message: message),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            message.senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(message.receivedAt),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message.senderAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Text(
                          'to me',
                          style: TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 15,
                          color: AppPalette.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.reply_outlined,
                size: 21,
                color: AppPalette.muted,
              ),
              const SizedBox(width: 14),
              const Icon(Icons.more_vert, size: 21, color: AppPalette.muted),
            ],
          ),
          const SizedBox(height: 26),
          if (message.kind == 'demo_code')
            _demoCodeCard()
          else if (message.kind == 'demo_alert')
            _alertCard()
          else
            _plainBody(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _footerAction(Icons.reply, 'Reply')),
              const SizedBox(width: 10),
              Expanded(child: _footerAction(Icons.forward, 'Forward')),
              const SizedBox(width: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppPalette.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.mood_outlined, size: 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _plainBody() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message.body,
      style: const TextStyle(fontSize: 15, height: 1.7, color: AppPalette.text),
    ),
  );

  Widget _demoCodeCard() {
    final code = message.code?.trim();
    final hasCode = code != null && code.isNotEmpty;

    // Style the sender label for Deriv-themed demonstration messages only.
    // Keep the code and disclaimer explicitly fictional and non-functional.
    final sender = message.senderName.trim().toLowerCase();
    final isDerivDemo =
        sender == 'deriv' || sender == 'trading demo' || sender == 'deriv demo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isDerivDemo ? 'deriv' : message.senderName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              fontStyle: isDerivDemo ? FontStyle.italic : FontStyle.normal,
              color: isDerivDemo
                  ? const Color(0xFFFF444F)
                  : AppPalette.text,
            ),
          ),

          const SizedBox(height: 25),

          // Actual message body from Supabase
          Text(
            message.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppPalette.text,
            ),
          ),

          if (hasCode) ...[
            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 7),
          const Text(
            'This code cannot verify real accounts or withdrawals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppPalette.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(
              Icons.shield_outlined,
              color: AppPalette.blue,
              size: 40,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            message.subject,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 18),

          Text(
            message.body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppPalette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerAction(IconData icon, String label) => SizedBox(
    height: 42,
    child: OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: AppPalette.surfaceContainerLow,
        side: BorderSide.none,
      ),
      icon: Icon(icon, size: 19),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    ),
  );

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
