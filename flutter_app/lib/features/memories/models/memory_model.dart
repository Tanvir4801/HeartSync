import 'package:cloud_firestore/cloud_firestore.dart';

class Memory {
  final String id;
  final String type; // 'photo' | 'video'
  final String url;
  final String caption;
  final DateTime date;
  final List<String> tags;
  final bool isFavorite;
  final String? albumId;

  const Memory({
    required this.id,
    required this.type,
    required this.url,
    required this.caption,
    required this.date,
    this.tags = const [],
    this.isFavorite = false,
    this.albumId,
  });

  factory Memory.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Memory(
      id: doc.id,
      type: d['type'] ?? 'photo',
      url: d['url'] ?? '',
      caption: d['caption'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(d['tags'] ?? []),
      isFavorite: d['isFavorite'] ?? false,
      albumId: d['albumId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'url': url,
    'caption': caption,
    'date': Timestamp.fromDate(date),
    'tags': tags,
    'isFavorite': isFavorite,
    if (albumId != null) 'albumId': albumId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
