import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, voice, quick }

class Message {
  final String id;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      type: MessageType.values.firstWhere((t) => t.name == (d['type'] ?? 'text'), orElse: () => MessageType.text),
      content: d['content'] ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'type': type.name,
    'content': content,
    'sentAt': FieldValue.serverTimestamp(),
    'readAt': null,
  };
}
