class MailMessage {
  const MailMessage({
    required this.id,
    required this.senderName,
    required this.senderAddress,
    required this.subject,
    required this.preview,
    required this.body,
    required this.receivedAt,
    required this.avatarLetter,
    required this.avatarColor,
    this.category = 'primary',
    this.kind = 'plain',
    this.isRead = false,
    this.isStarred = false,
    this.demoKey,
  });

  final String id;
  final String senderName;
  final String senderAddress;
  final String subject;
  final String preview;
  final String body;
  final DateTime receivedAt;
  final String avatarLetter;
  final String avatarColor;
  final String category;
  final String kind;
  final bool isRead;
  final bool isStarred;
  final String? demoKey;

  factory MailMessage.fromRow(Map<String, dynamic> row) {
    return MailMessage(
      id: row['id'] as String,
      senderName: row['sender_name'] as String,
      senderAddress: row['sender_address'] as String,
      subject: row['subject'] as String,
      preview: row['preview'] as String? ?? '',
      body: row['body'] as String? ?? '',
      receivedAt: DateTime.parse(row['received_at'] as String).toLocal(),
      avatarLetter: row['avatar_letter'] as String? ?? 'M',
      avatarColor: row['avatar_color'] as String? ?? '#1A73E8',
      category: row['category'] as String? ?? 'primary',
      kind: row['kind'] as String? ?? 'plain',
      isRead: row['is_read'] as bool? ?? false,
      isStarred: row['is_starred'] as bool? ?? false,
      demoKey: row['demo_key'] as String?,
    );
  }

  MailMessage copyWith({bool? isRead, bool? isStarred}) {
    return MailMessage(
      id: id,
      senderName: senderName,
      senderAddress: senderAddress,
      subject: subject,
      preview: preview,
      body: body,
      receivedAt: receivedAt,
      avatarLetter: avatarLetter,
      avatarColor: avatarColor,
      category: category,
      kind: kind,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      demoKey: demoKey,
    );
  }

  Map<String, dynamic> toSeedRow(String ownerId) => {
    'owner_id': ownerId,
    'demo_key': demoKey,
    'sender_name': senderName,
    'sender_address': senderAddress,
    'subject': subject,
    'preview': preview,
    'body': body,
    'received_at': receivedAt.toUtc().toIso8601String(),
    'avatar_letter': avatarLetter,
    'avatar_color': avatarColor,
    'category': category,
    'kind': kind,
    'is_read': isRead,
  };
}
