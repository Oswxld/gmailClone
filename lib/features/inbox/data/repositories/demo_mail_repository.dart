import '../../domain/models/mail_message.dart';
import '../../domain/repositories/mail_repository.dart';

class DemoMailRepository implements MailRepository {
  final List<MailMessage> _messages = buildExampleMessages();
  String _letter = 'O';

  @override
  Future<List<MailMessage>> getInbox() async {
    return List.of(_messages)
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  @override
  Future<void> markRead(String messageId) async {
    final i = _messages.indexWhere((m) => m.id == messageId);
    if (i >= 0) _messages[i] = _messages[i].copyWith(isRead: true);
  }

  @override
  Future<void> setStar(String messageId, bool starred) async {
    final i = _messages.indexWhere((m) => m.id == messageId);
    if (i >= 0) _messages[i] = _messages[i].copyWith(isStarred: starred);
  }

  @override
  Future<String> getAvatarLetter() async => _letter;

  @override
  Future<void> setAvatarLetter(String letter) async {
    _letter = letter;
  }

  @override
  Future<MailMessage> generateTestMessage() async {
    final message = MailMessage(
      id: 'test-${DateTime.now().microsecondsSinceEpoch}',
      senderName: 'Trading Demo',
      senderAddress: 'alerts@example.test',
      subject: 'Demo verification code: 123456',
      preview: 'A test message, not a real account verification.',
      body: 'This demonstration code is 123456. It cannot authorize any real transaction.',
      receivedAt: DateTime.now(),
      avatarLetter: 'T',
      avatarColor: '#FF444F',
      kind: 'demo_code',
      isRead: false,
    );
    _messages.insert(0, message);
    return message;
  }
}

/// Seed data exists only for visual testing. Addresses are reserved demo
/// domains, and none of these messages is a genuine provider notification.
List<MailMessage> buildExampleMessages() {
  final now = DateTime.now();

  MailMessage mail(
    String id,
    String sender,
    String address,
    String subject,
    String preview,
    String body,
    int minutesAgo,
    String letter,
    String color, {
    bool read = false,
    String category = 'primary',
    String kind = 'plain',
  }) {
    return MailMessage(
      id: id,
      demoKey: id,
      senderName: sender,
      senderAddress: address,
      subject: subject,
      preview: preview,
      body: body,
      receivedAt: now.subtract(Duration(minutes: minutesAgo)),
      avatarLetter: letter,
      avatarColor: color,
      isRead: read,
      category: category,
      kind: kind,
    );
  }

  return [
    mail('studio', 'Studio Updates', 'studio@example.test',
      'Your portrait studio is ready',
      'Turn a photo into a studio-ready profile picture...',
      'Your studio project is ready.\n\nOpen your creative workspace to review your new portrait.\n\n— Studio Updates',
      12, 'S', '#273B45'),
    mail('project', 'Project Updates', 'updates@example.test',
      'More access to advanced tools',
      'Explore new features in your workspace...',
      'Hello!\n\nYou can now explore the latest features available in the demo workspace.\n\n— Project Updates',
      110, 'P', '#2C665D', read: true),
    mail('trading-news', 'Trading Demo', 'news@example.test',
      'Platform maintenance notice',
      'Information about planned demo maintenance...',
      'Trading Demo\n\nThis simulated service will undergo maintenance on Saturday from 02:00 to 03:00 UTC. No real accounts are affected.',
      355, 'T', '#FF444F'),
    mail('workspace', 'Workspace Team', 'team@example.test',
      'A new invitation to collaborate',
      'You have been invited to join a project...',
      'Hi,\n\nYou have an invitation to join a demo workspace.\n\nThis sample message is for visual testing.',
      540, 'W', '#1559BD', read: true),
    mail('account', 'Account Demo', 'security@example.test',
      'Security alert: New sign-in detected',
      'A new sign-in was recorded in your demo account...',
      'A simulated new sign-in was recorded.\n\nDevice: Chrome on macOS\nLocation: Test environment\n\nNo real account activity occurred.',
      730, 'A', '#1A73E8', kind: 'demo_alert'),
    mail('design', 'Design Weekly', 'digest@example.test',
      'Your weekly design inspiration',
      'A selection of UI patterns and creative ideas...',
      'Welcome to Design Weekly!\n\nThis week: Material Design patterns, thoughtful spacing, and accessible interfaces.',
      1510, 'D', '#D46B17', read: true, category: 'promotions'),
    mail('community', 'Community', 'hello@example.test',
      'You appeared in this week’s community roundup',
      'See what your community is discussing...',
      'Hello!\n\nHere is a roundup of activity from the demo community.\n\nEnjoy exploring!',
      1740, 'C', '#147AA3', category: 'social'),
    mail('storage', 'Cloud Drive', 'drive@example.test',
      'Your files are backed up',
      'Your latest upload was completed successfully...',
      'Your demonstration files were saved successfully.\n\nThis is not a real cloud storage notification.',
      1980, 'C', '#187C47', read: true),
    mail('calendar', 'Calendar', 'calendar@example.test',
      'Reminder: Weekly project review',
      'Your event begins tomorrow at 10:00...',
      'Weekly project review\n\nTomorrow at 10:00.\n\nThis is a sample calendar reminder.',
      2520, 'C', '#1967D2'),
    mail('newsletter', 'Product Notes', 'notes@example.test',
      'October product round-up',
      'Fresh ideas for builders and developers...',
      'Hello!\n\nExplore product design, performance, and accessibility in this month’s demo round-up.',
      3820, 'P', '#B35E55', read: true, category: 'updates'),
    mail('learning', 'Course Team', 'learn@example.test',
      'Your next lesson is available',
      'Continue your software development course...',
      'Hi there!\n\nYour next learning module is available. Keep building!',
      6200, 'C', '#6A58B6', read: true),
    mail('delivery', 'Delivery Demo', 'orders@example.test',
      'Your package status has changed',
      'The demo order is now in transit...',
      'Your demonstration order has moved to in transit.\n\nNo physical shipment was created.',
      8100, 'D', '#A65E27', read: true, category: 'updates'),
    mail('welcome', 'Mail Demo', 'welcome@example.test',
      'Welcome to your demo inbox',
      'Explore realistic-looking sample mail...',
      'Welcome!\n\nThis is an independent demonstration interface. It does not connect to Gmail or display genuine messages.',
      11000, 'M', '#1A73E8', read: true),
  ];
}
