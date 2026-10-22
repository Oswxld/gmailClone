import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gmail_clone/features/inbox/presentation/screens/inbox_screen.dart';

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
}

void _noop() {}
