enum RiskLevel { normal, caution, urgent }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final RiskLevel riskLevel;
  final String conversationId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.riskLevel = RiskLevel.normal,
    this.conversationId = 'default',
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'text': text, 'isUser': isUser ? 1 : 0,
    'timestamp': timestamp.toIso8601String(), 'riskLevel': riskLevel.index,
    'conversationId': conversationId,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'], text: map['text'], isUser: map['isUser'] == 1,
    timestamp: DateTime.parse(map['timestamp']),
    riskLevel: RiskLevel.values[map['riskLevel'] ?? 0],
    conversationId: map['conversationId'] ?? 'default',
  );
}
