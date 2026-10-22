import 'package:flutter/material.dart';

import '../../domain/models/mail_message.dart';

/// Shared inbox/details avatar. Photos and company logos are bundled assets;
/// unrecognized senders continue to use their existing initial-letter avatar.
class MailSenderAvatar extends StatelessWidget {
  const MailSenderAvatar({
    required this.message,
    this.radius = 20,
    super.key,
  });

  final MailMessage message;
  final double radius;

  static const _iconDirectory = 'assets/icons/messages_icons/';
  static const _images = <String, String>{
    'seed2-facebook': 'facebook.png',
    'seed2-chatgpt': 'chatgpt.png',
    'seed2-linkedin': 'linkedin.png',
    'seed2-vercel': 'vercel.png',
    'seed2-vercel-summary': 'vercel.png',
    'seed2-nyumba': 'nyumba_zetu.png',
    'seed2-nyumba-maintenance': 'nyumba_zetu.png',
    'seed2-instagram': 'instagram.png',
  };

  @override
  Widget build(BuildContext context) {
    // Fictional personal emails use a simple, consistent Gmail-style initial
    // instead of a shared placeholder/profile picture.
    if (message.demoKey == 'seed2-miriam' ||
        message.demoKey == 'seed2-brian') {
      return _personalInitialAvatar();
    }

    if (message.kind == 'demo_code') {
      // Identical image to android/.../drawable-nodpi/sender_avatar.png.
      return _imageAvatar('sender_avatar.png', inset: 0);
    }

    if (message.demoKey == 'seed2-netflix' ||
        message.demoKey == 'seed2-netflix-weekend') {
      // No Netflix PNG was present in the uploaded icon folder.
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.black,
        child: Text(
          'N',
          style: TextStyle(
            color: const Color(0xFFE50914),
            fontSize: radius * 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final name = _images[message.demoKey];
    if (name != null) {
      return _imageAvatar(name, inset: 3);
    }

    return _fallbackAvatar();
  }

  Widget _personalInitialAvatar() {
    final email = message.senderAddress.trim();
    final initial = email.isNotEmpty
        ? email.substring(0, 1).toUpperCase()
        : message.avatarLetter.toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF6B7F9D),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.95,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _imageAvatar(String filename, {required double inset}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF4F5F7),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Image.asset(
            '$_iconDirectory$filename',
            width: radius * 2 - inset * 2,
            height: radius * 2 - inset * 2,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final colorValue = int.tryParse(
      message.avatarColor.replaceFirst('#', ''),
      radix: 16,
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorValue == null
          ? const Color(0xFF1A73E8)
          : Color(0xFF000000 | colorValue),
      child: Text(
        message.avatarLetter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
