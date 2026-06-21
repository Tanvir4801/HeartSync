import 'package:cloud_firestore/cloud_firestore.dart';

enum MilestoneCategory { firstMeeting, firstDate, trip, favorite, custom }

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final MilestoneCategory category;
  final double? lat;
  final double? lng;
  final String? photoUrl;

  const Milestone({
    required this.id, required this.title, required this.description,
    required this.date, required this.category,
    this.lat, this.lng, this.photoUrl,
  });

  factory Milestone.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Milestone(
      id: doc.id, title: d['title'] ?? '', description: d['description'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: MilestoneCategory.values.firstWhere(
        (c) => c.name == (d['category'] ?? 'custom'), orElse: () => MilestoneCategory.custom),
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      photoUrl: d['photoUrl'],
    );
  }

  String get categoryIcon {
    switch (category) {
      case MilestoneCategory.firstMeeting: return '💫';
      case MilestoneCategory.firstDate: return '🌹';
      case MilestoneCategory.trip: return '✈️';
      case MilestoneCategory.favorite: return '⭐';
      case MilestoneCategory.custom: return '📍';
    }
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'description': description,
    'date': Timestamp.fromDate(date), 'category': category.name,
    if (lat != null) 'lat': lat, if (lng != null) 'lng': lng,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
