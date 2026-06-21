import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../models/milestone_model.dart';

class MilestoneRepository {
  final FirestoreService _fs = FirestoreService();

  Stream<List<Milestone>> milestonesStream(String coupleId) {
    return _fs.sub(coupleId, 'milestones')
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Milestone.fromDoc).toList());
  }

  Future<void> addMilestone(String coupleId, Milestone m) async {
    await _fs.sub(coupleId, 'milestones').add(m.toMap());
  }

  Future<void> updateMilestone(String coupleId, Milestone m) async {
    await _fs.sub(coupleId, 'milestones').doc(m.id).update(m.toMap());
  }

  Future<void> deleteMilestone(String coupleId, String id) async {
    await _fs.sub(coupleId, 'milestones').doc(id).delete();
  }
}
