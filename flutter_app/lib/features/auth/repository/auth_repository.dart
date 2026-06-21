import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/firestore_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(rand ~/ (i + 1)) % chars.length]).join();
  }

  Future<String> createCoupleSpace(String uid, String email, DateTime anniversary) async {
    final coupleId = const Uuid().v4();
    final inviteCode = _generateInviteCode();
    await _fs.coupleDoc(coupleId).set({
      'members': [uid],
      'memberEmails': [email],
      'anniversaryDate': Timestamp.fromDate(anniversary),
      'inviteCode': inviteCode,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'streak': 0,
    });
    await _initSubcollections(coupleId, uid);
    return coupleId;
  }

  Future<String?> joinCoupleSpace(String uid, String email, String inviteCode) async {
    final coupleId = await _fs.findCoupleByInviteCode(inviteCode);
    if (coupleId == null) return null;
    await _fs.coupleDoc(coupleId).update({
      'members': FieldValue.arrayUnion([uid]),
      'memberEmails': FieldValue.arrayUnion([email]),
      'status': 'active',
      'linkedAt': FieldValue.serverTimestamp(),
    });
    return coupleId;
  }

  Future<String?> getExistingCoupleId(String uid) =>
      _fs.getCoupleIdForUser(uid);

  Future<void> _initSubcollections(String coupleId, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final batteryRef = _fs.coupleDoc(coupleId).collection('battery').doc('current');
    batch.set(batteryRef, {'level': 50, 'lastUpdated': FieldValue.serverTimestamp()});
    await batch.commit();
  }
}
