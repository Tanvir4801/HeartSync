import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirestoreService _fs = FirestoreService();

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<Message>> messagesStream(String coupleId) {
    return _fs.sub(coupleId, 'messages')
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  Future<void> sendMessage(String coupleId, Message message) async {
    await _fs.sub(coupleId, 'messages').add(message.toMap());
    try { await _fs.updateDailyAction(coupleId, message.senderId); } catch (_) {}
  }

  Future<void> markRead(String coupleId, String messageId) async {
    try {
      await _fs.sub(coupleId, 'messages').doc(messageId).update({'readAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  // ── Typing ─────────────────────────────────────────────────────────────────

  Future<void> setTyping(String coupleId, String uid, bool isTyping) async {
    try {
      final ref = _fs.coupleDoc(coupleId).collection('typing').doc(uid);
      if (isTyping) {
        await ref.set({'timestamp': FieldValue.serverTimestamp()});
      } else {
        await ref.delete();
      }
    } catch (_) {}
  }

  Stream<bool> partnerTypingStream(String coupleId, String myUid) {
    return _fs.coupleDoc(coupleId).collection('typing')
        .snapshots()
        .map((s) => s.docs.any((d) => d.id != myUid));
  }

  // ── Presence ───────────────────────────────────────────────────────────────

  Future<void> updatePresence(String coupleId, String uid) async {
    try {
      await _fs.coupleDoc(coupleId).collection('presence').doc(uid).set(
        {'lastSeen': FieldValue.serverTimestamp(), 'uid': uid},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Stream<DocumentSnapshot> partnerPresenceStream(String coupleId, String partnerUid) {
    return _fs.coupleDoc(coupleId).collection('presence').doc(partnerUid).snapshots();
  }

  // ── Sleep Together Mode ────────────────────────────────────────────────────

  Future<void> setSleepMode(String coupleId, String uid, bool sleeping) async {
    try {
      await _fs.coupleDoc(coupleId).collection('sleep').doc(uid).set({
        'sleeping': sleeping,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot> sleepStream(String coupleId) {
    return _fs.coupleDoc(coupleId).collection('sleep').snapshots();
  }
}
