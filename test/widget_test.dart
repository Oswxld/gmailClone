import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gmail_clone/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:gmail_clone/features/inbox/presentation/screens/email_details_screen.dart';
import 'package:gmail_clone/features/inbox/presentation/widgets/mail_sender_avatar.dart';
import 'package:gmail_clone/features/inbox/data/repositories/demo_mail_repository.dart';

void main() {
  testWidgets('Guest inbox opens and closes a sample email',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: InboxScreen(
            isDemo: true,
            onSignOut: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Primary'), findsOneWidget);

    await tester.tap(find.text('Are we still on for Saturday?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Are we still on for Saturday afternoon?'),
        findsOneWidget);

    await tester.tap(find.byTooltip('Back to inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Primary'), findsOneWidget);
  });
  testWidgets('Personal email avatars use address initials, not pictures',
      (WidgetTester tester) async {
    final people = buildExampleMessages()
        .where((m) =>
            m.demoKey == 'seed2-miriam' || m.demoKey == 'seed2-brian')
        .toList();

    for (final message in people) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MailSenderAvatar(message: message),
          ),
        ),
      );
      expect(
        find.text(message.senderAddress.substring(0, 1).toUpperCase()),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, const Color(0xFF6B7F9D));
    }
  });

  testWidgets('The Deriv demo code card uses italic red lowercase lettering',
      (WidgetTester tester) async {
    final message = buildExampleMessages()
        .firstWhere((m) => m.kind == 'demo_code');
    await tester.pumpWidget(MaterialApp(
      home: EmailDetailsScreen(message: message),
    ));

    final wordmark = tester.widget<Text>(find.text('deriv'));
    expect(wordmark.style?.fontStyle, FontStyle.italic);
    expect(wordmark.style?.color, const Color(0xFFFF444F));
    expect(find.textContaining('cannot verify real accounts'), findsOneWidget);
  });
}

void _noop() {}
