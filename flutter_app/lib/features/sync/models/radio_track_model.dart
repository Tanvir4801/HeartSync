import 'package:cloud_firestore/cloud_firestore.dart';

// ─── RadioTrack ───────────────────────────────────────────────────────────────
// Firestore: couples/{coupleId}/radioTracks/{id}

class RadioTrack {
  final String id;
  final String title;
  final String artistName;
  final String uploadedBy;
  final String storageUrl;
  final int durationMs;
  final DateTime createdAt;

  const RadioTrack({
    required this.id,
    required this.title,
    required this.artistName,
    required this.uploadedBy,
    required this.storageUrl,
    required this.durationMs,
    required this.createdAt,
  });

  factory RadioTrack.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RadioTrack(
      id: doc.id,
      title: d['title'] ?? 'Untitled',
      artistName: d['artistName'] ?? '',
      uploadedBy: d['uploadedBy'] ?? '',
      storageUrl: d['storageUrl'] ?? '',
      durationMs: (d['durationMs'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'artistName': artistName,
    'uploadedBy': uploadedBy,
    'storageUrl': storageUrl,
    'durationMs': durationMs,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get formattedDuration {
    final s = durationMs ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}
