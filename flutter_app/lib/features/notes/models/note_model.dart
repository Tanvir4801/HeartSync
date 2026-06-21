import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String text;
  final String authorId;
  final DateTime openDate;
  final bool opened;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.text,
    required this.authorId,
    required this.openDate,
    required this.opened,
    required this.createdAt,
  });

  factory Note.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      text: d['text'] ?? '',
      authorId: d['authorId'] ?? '',
      openDate: (d['openDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      opened: d['opened'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isUnlocked => DateTime.now().isAfter(openDate);

  Map<String, dynamic> toMap() => {
    'text': text,
    'authorId': authorId,
    'openDate': Timestamp.fromDate(openDate),
    'opened': opened,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
