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
      senderAddress: 'verification@demo.example.test',
      subject: 'Your demo verification code: 482913',
      preview: 'Use 482913 for this simulated sign-in.',
      body: 'Here is your one-time demonstration code: 482913.\n\n'
          'This is a sample code; it cannot authenticate any real account.',
      code: '482913',
      receivedAt: DateTime.now(),
      avatarLetter: 'T',
      avatarColor: '#FF444F',
      kind: 'demo_code',
    );
    _messages.insert(0, message);
    return message;
  }
}

/// All messages below are fictional inbox fixtures, not emails sent by the
/// named brands or by real people. Sender domains use the reserved .test TLD.
///
/// The keys remain stable across logins; Supabase stores one row per user/key.
/// Keep this list aligned with legacySeedKeys in SupabaseMailRepository.
List<MailMessage> buildExampleMessages() {
  final now = DateTime.now();

  MailMessage mail(
    String key,
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
    String? code,
  }) {
    return MailMessage(
      id: key,
      demoKey: key,
      senderName: sender,
      senderAddress: address,
      subject: subject,
      preview: preview,
      body: body,
      code: code,
      receivedAt: now.subtract(Duration(minutes: minutesAgo)),
      avatarLetter: letter,
      avatarColor: color,
      isRead: read,
      category: category,
      kind: kind,
    );
  }

  return [
    mail('seed2-miriam', 'Miriam Wanjiku', 'miriam.wanjiku@example.test',
      'Are we still on for Saturday?',
      'Hey! Just checking if our Saturday plan is still happening.',
      'Hey!\n\nAre we still on for Saturday afternoon? '
      'I found a nice little coffee spot near town.\n\n'
      'Let me know what works for you.\n\nMiriam',
      14, 'M', '#9B6A4E'),
    mail('seed2-netflix', 'Netflix', 'updates@netflix.example.test',
      'A few shows you might enjoy this weekend',
      'There are some new picks waiting on your watchlist.',
      'Your weekend watchlist could use something new.\n\n'
      'Explore a few fresh series, save your favorites, and pick up '
      'where you left off.\n\n'
      'This is a fictional Netflix-themed inbox sample, not an actual Netflix email.',
      65, 'N', '#E50914', category: 'promotions'),
    mail('seed2-chatgpt', 'ChatGPT', 'updates@chatgpt.example.test',
      'Your ideas deserve a place to grow',
      'Keep your notes, drafts, and experiments moving forward.',
      'Hello!\n\nWhether you are planning a project or exploring '
      'something new, your next idea can start with a simple prompt.\n\n'
      'This is a fictional ChatGPT-themed inbox sample.',
      147, 'C', '#111827'),
    mail('seed2-vercel', 'Vercel', 'deployments@vercel.example.test',
      'Preview deployment is ready',
      'A preview build for portfolio-demo is available to review.',
      'Deployment preview\n\nProject: portfolio-demo\n'
      'Branch: feature/homepage\nStatus: Ready\n\n'
      'This is a simulated deployment notice, not a real Vercel event.',
      224, 'V', '#000000', category: 'updates'),
    mail('seed2-brian', 'Brian Otieno', 'brian.otieno@example.test',
      'Quick question about the project',
      'Do you have time to review the updated screens?',
      'Hey,\n\nI made a few adjustments to the mockups and wanted '
      'to get your thoughts before we move on.\n\n'
      'Let me know when you are free.\n\nBrian',
      391, 'B', '#607D8B'),
    mail('seed2-facebook', 'Facebook', 'notifications@facebook.example.test',
      'Your community has some new updates',
      'People in your groups have been sharing new posts.',
      'There is fresh activity in the communities you follow.\n\n'
      'Catch up on the conversations that interest you.\n\n'
      'This is a fictional Facebook-themed inbox sample.',
      612, 'F', '#1877F2', category: 'social'),
    mail('seed2-linkedin', 'LinkedIn', 'updates@linkedin.example.test',
      'New conversations in your network',
      'Your professional network has been sharing ideas.',
      'Your network is growing.\n\n'
      'Check out new conversations, learn what people are building, '
      'and discover a few professional updates.\n\n'
      'This is a fictional LinkedIn-themed inbox sample.',
      911, 'L', '#0A66C2', category: 'social'),
    mail('seed2-nyumba', 'Nyumba Zetu', 'hello@nyumba-zetu.example.test',
      'Your October property update',
      'A short update about shared facilities and maintenance.',
      'Hello,\n\nHere is a sample update from the Nyumba Zetu '
      'property team. Routine maintenance of the common areas is '
      'planned for later this week.\n\n'
      'This is a fictional property notice for demonstration purposes.',
      1310, 'N', '#111111', category: 'updates'),
    mail('seed2-instagram', 'Instagram', 'activity@instagram.example.test',
      'A little activity you may have missed',
      'There are new posts and stories to catch up with.',
      'Your friends have been sharing moments and stories.\n\n'
      'Drop by when you have a moment to explore what is new.\n\n'
      'This is a fictional Instagram-themed inbox sample.',
      1790, 'I', '#E1306C', category: 'social', read: true),
    mail('seed2-code', 'Trading Demo', 'verification@demo.example.test',
      'Your demo verification code: 482913',
      'Use the sample code 482913 to explore the verification layout.',
      'Here is your one-time demonstration code: 482913.\n\n'
      'It is only a sample and cannot authorize a real sign-in, payment, or withdrawal.',
      2250, 'T', '#FF444F', kind: 'demo_code', code: '482913'),
    mail('seed2-netflix-weekend', 'Netflix', 'recommendations@netflix.example.test',
      'Still deciding what to watch?',
      'Your demo watchlist has a few more ideas.',
      'Looking for something to watch?\n\n'
      'Settle in and pick a story that suits the mood.\n\n'
      'This is a fictional Netflix-themed inbox sample.',
      3150, 'N', '#E50914', category: 'promotions', read: true),
    mail('seed2-vercel-summary', 'Vercel', 'activity@vercel.example.test',
      'Your weekly project summary',
      'A quick look at sample deployment activity this week.',
      'Here is your simulated weekly summary.\n\n'
      'Project: portfolio-demo\n'
      'Successful previews: 3\nBuild errors: 0\n\n'
      'These figures are examples only.',
      5400, 'V', '#000000', category: 'updates', read: true),
    mail('seed2-nyumba-maintenance', 'Nyumba Zetu',
      'support@nyumba-zetu.example.test',
      'Update on your maintenance request',
      'The sample maintenance ticket has been reviewed.',
      'Hello,\n\nYour demonstration maintenance request '
      'has been reviewed and scheduled for follow-up.\n\n'
      'This is an example notification, not a real service request.',
      9800, 'N', '#111111', category: 'updates', read: true),
  ];
}
