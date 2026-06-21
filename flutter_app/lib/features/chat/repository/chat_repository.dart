import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirestoreService _fs = FirestoreService();

  Stream<List<Message>> messagesStream(String coupleId) {
    return _fs.sub(coupleId, 'messages')
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  Future<void> sendMessage(String coupleId, Message message) async {
    await _fs.sub(coupleId, 'messages').add(message.toMap());
    await _fs.updateDailyAction(coupleId, message.senderId);
  }

  Future<void> markRead(String coupleId, String messageId) async {
    await _fs.sub(coupleId, 'messages').doc(messageId).update({'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> setTyping(String coupleId, String uid, bool isTyping) async {
    final ref = _fs.coupleDoc(coupleId).collection('typing').doc(uid);
    if (isTyping) {
      await ref.set({'timestamp': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Stream<bool> partnerTypingStream(String coupleId, String myUid) {
    return _fs.coupleDoc(coupleId).collection('typing')
        .snapshots()
        .map((s) => s.docs.any((d) => d.id != myUid));
  }
}
