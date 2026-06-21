import '../../../core/firestore_service.dart';
import '../models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteRepository {
  final FirestoreService _fs = FirestoreService();

  Stream<List<Note>> notesStream(String coupleId) {
    return _fs.sub(coupleId, 'notes')
        .orderBy('openDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Note.fromDoc).toList());
  }

  Future<void> addNote(String coupleId, Note note) async {
    await _fs.sub(coupleId, 'notes').add(note.toMap());
    await _fs.updateDailyAction(coupleId, note.authorId);
  }

  Future<void> markOpened(String coupleId, String noteId) async {
    await _fs.sub(coupleId, 'notes').doc(noteId).update({'opened': true});
  }

  Future<void> deleteNote(String coupleId, String noteId) async {
    await _fs.sub(coupleId, 'notes').doc(noteId).delete();
  }
}
