class MailMessage {
  const MailMessage({
     this.code,
     this.body2,
     this.withdrawalAddress,
     this.transactionId,
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
final String? code;
  final String? body2;
  final String? withdrawalAddress;
  final String? transactionId;
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

  // Supabase may return null for optional/manual message fields.
  // Keep widget-facing values non-null so existing inbox screens remain safe.
  static String _text(dynamic value, [String fallback = '']) =>
      value is String ? value : fallback;

  static DateTime _date(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  }

  factory MailMessage.fromRow(Map<String, dynamic> row) {
    return MailMessage(
      id: _text(row['id']),
      senderName: _text(row['sender_name'], 'Unknown sender'),
      senderAddress: _text(row['sender_address']),
      subject: _text(row['subject'], '(No subject)'),
      preview: _text(row['preview']),
      body: _text(row['body']),
      receivedAt: _date(row['received_at']),
      avatarLetter: _text(row['avatar_letter'], 'M'),
      avatarColor: _text(row['avatar_color'], '#1A73E8'),
      category: _text(row['category'], 'primary'),
      kind: _text(row['kind'], 'plain'),
      isRead: row['is_read'] == true,
      isStarred: row['is_starred'] == true,
      demoKey: row['demo_key'] is String ? row['demo_key'] as String : null,
      code: row['code'] is String ? row['code'] as String : null,
      body2: row['body2'] is String ? row['body2'] as String : null,
      withdrawalAddress: row['withdrawal_address'] is String
          ? row['withdrawal_address'] as String : null,
      transactionId: row['transaction_id'] is String
          ? row['transaction_id'] as String : null,
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
      code: code,
      body2: body2,
      withdrawalAddress: withdrawalAddress,
      transactionId: transactionId,
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
    'code': code,
    'body2': body2,
    'withdrawal_address': withdrawalAddress,
    'transaction_id': transactionId,
  };
}
