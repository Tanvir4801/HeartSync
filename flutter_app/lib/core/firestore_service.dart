import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get couples => _db.collection('couples');

  DocumentReference coupleDoc(String coupleId) => couples.doc(coupleId);

  CollectionReference sub(String coupleId, String col) =>
      couples.doc(coupleId).collection(col);

  Future<String?> getCoupleIdForUser(String uid) async {
    final snap = await couples
        .where('members', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<String?> findCoupleByInviteCode(String code) async {
    final snap = await couples
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> updateDailyAction(String coupleId, String uid) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final ref = coupleDoc(coupleId);
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>?;
    final actions = Map<String, dynamic>.from(data?['dailyActions'] ?? {});
    final todayActions = List<String>.from(actions[dateKey] ?? []);
    if (!todayActions.contains(uid)) {
      todayActions.add(uid);
      actions[dateKey] = todayActions;
      await ref.update({'dailyActions': actions});
      await _updateStreak(coupleId, dateKey, actions, data?['members'] ?? []);
    }
  }

  Future<void> _updateStreak(String coupleId, String today,
      Map<String, dynamic> actions, List members) async {
    final todayActions = List<String>.from(actions[today] ?? []);
    final bothActed = members.every((uid) => todayActions.contains(uid));
    if (bothActed) {
      await coupleDoc(coupleId).update({
        'streak': FieldValue.increment(1),
        'lastStreakDate': today,
      });
    }
  }
}
