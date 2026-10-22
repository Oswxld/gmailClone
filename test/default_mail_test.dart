import 'package:flutter_test/flutter_test.dart';
import 'package:gmail_clone/features/inbox/data/repositories/demo_mail_repository.dart';

void main() {
  test('seeded inbox has the requested sender mix and unique keys', () {
    final samples = buildExampleMessages();
    expect(samples.length, 13);
    expect(
      samples.map((mail) => mail.demoKey).toSet().length,
      samples.length,
    );
    expect(
      samples.where((mail) => mail.senderName == 'Miriam Wanjiku').length,
      1,
    );
    expect(
      samples.where((mail) => mail.senderName == 'Brian Otieno').length,
      1,
    );
    for (final sender in [
      'Netflix',
      'Facebook',
      'Nyumba Zetu',
      'Vercel',
      'ChatGPT',
      'LinkedIn',
    ]) {
      expect(samples.any((mail) => mail.senderName == sender), isTrue);
    }
    final codes = samples.where((mail) => mail.kind == 'demo_code').toList();
    expect(codes.length, 1);
    expect(codes.single.code, '482913');
    expect(codes.single.body, contains('482913'));
  });
}
