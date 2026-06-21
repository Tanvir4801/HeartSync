import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final String status; // 'pending' | 'completed'
  final List<String> completedBy;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.status,
    required this.completedBy,
  });

  factory Challenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      xpReward: d['xpReward'] ?? 50,
      status: d['status'] ?? 'pending',
      completedBy: List<String>.from(d['completedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'xpReward': xpReward,
    'status': status,
    'completedBy': completedBy,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

const List<Map<String, dynamic>> kDefaultChallenges = [
  {'title': 'Share a voice note', 'description': 'Record and send a voice note today', 'xpReward': 50},
  {'title': 'Add a memory together', 'description': 'Upload a photo from a shared moment', 'xpReward': 40},
  {'title': 'Write a love note', 'description': 'Write a note that unlocks in the future', 'xpReward': 60},
  {'title': 'Daily mood check', 'description': 'Both partners log their mood today', 'xpReward': 30},
  {'title': 'Send 10 messages', 'description': 'Have an active chat day with 10+ messages', 'xpReward': 35},
  {'title': 'Virtual hug day', 'description': 'Send 3 virtual hugs in one day', 'xpReward': 25},
  {'title': '7-day streak', 'description': 'Maintain a 7-day activity streak', 'xpReward': 100},
];
