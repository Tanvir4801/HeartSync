import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../models/challenge_model.dart';

class GamificationRepository {
  final FirestoreService _fs = FirestoreService();

  Future<void> initChallenges(String coupleId) async {
    final existing = await _fs.sub(coupleId, 'challenges').limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final c in kDefaultChallenges) {
      final ref = _fs.sub(coupleId, 'challenges').doc();
      batch.set(ref, {...c, 'status': 'pending', 'completedBy': [], 'createdAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Stream<List<Challenge>> challengesStream(String coupleId) {
    return _fs.sub(coupleId, 'challenges').snapshots().map((s) => s.docs.map(Challenge.fromDoc).toList());
  }

  Future<void> completeChallenge(String coupleId, String challengeId, String uid, int xpReward) async {
    await _fs.sub(coupleId, 'challenges').doc(challengeId).update({
      'completedBy': FieldValue.arrayUnion([uid]),
      'status': 'completed',
    });
    await _fs.coupleDoc(coupleId).update({'xp': FieldValue.increment(xpReward)});
    await _updateBattery(coupleId, 5);
  }

  Future<void> _updateBattery(String coupleId, int delta) async {
    final ref = _fs.sub(coupleId, 'battery').doc('current');
    final snap = await ref.get();
    final current = (snap.data() as Map<String, dynamic>?)?['level'] as int? ?? 50;
    final newLevel = (current + delta).clamp(0, 100);
    await ref.set({'level': newLevel, 'lastUpdated': FieldValue.serverTimestamp()});
  }

  Stream<Map<String, dynamic>> xpStream(String coupleId) {
    return _fs.coupleDoc(coupleId).snapshots().map((s) {
      final d = s.data() as Map<String, dynamic>? ?? {};
      final xp = d['xp'] as int? ?? 0;
      return {'xp': xp, 'level': xp ~/ 100};
    });
  }

  Future<String> getDailyQuestion() async {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return kDailyQuestions[dayOfYear % kDailyQuestions.length];
  }
}

const List<String> kDailyQuestions = [
  'What\'s your happiest memory with me?',
  'If we could travel anywhere right now, where would you choose?',
  'What\'s one thing I do that always makes you smile?',
  'What does our perfect day together look like?',
  'What\'s a dream you haven\'t told me about yet?',
  'What song reminds you most of us?',
  'What\'s the little thing I do that means the most to you?',
  'When did you first realize you loved me?',
  'What\'s something you want us to experience together this year?',
  'What\'s your favorite thing about our relationship?',
];
