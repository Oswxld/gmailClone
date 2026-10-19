import '../models/mail_message.dart';

abstract class MailRepository {
  Future<List<MailMessage>> getInbox();
  Future<void> markRead(String messageId);
  Future<void> setStar(String messageId, bool starred);
  Future<String> getAvatarLetter();
  Future<void> setAvatarLetter(String letter);

  /// Creates a clearly labeled simulated message and notification for
  /// the currently signed-in user only.
  Future<MailMessage> generateTestMessage();
}
