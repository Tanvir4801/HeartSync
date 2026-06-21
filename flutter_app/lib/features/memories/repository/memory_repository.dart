import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/firestore_service.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  final FirestoreService _fs = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Memory>> memoriesStream(String coupleId) {
    return _fs.sub(coupleId, 'memories')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Memory.fromDoc).toList());
  }

  Future<String> uploadMedia(String coupleId, File file, String type) async {
    final id = const Uuid().v4();
    final ext = type == 'video' ? 'mp4' : 'jpg';
    final ref = _storage.ref('couples/$coupleId/memories/$id.$ext');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> addMemory(String coupleId, Memory memory) async {
    await _fs.sub(coupleId, 'memories').add(memory.toMap());
    await _fs.updateDailyAction(coupleId, memory.url);
  }

  Future<void> toggleFavorite(String coupleId, String memoryId, bool current) async {
    await _fs.sub(coupleId, 'memories').doc(memoryId).update({'isFavorite': !current});
  }

  Future<void> deleteMemory(String coupleId, String memoryId, String url) async {
    await _fs.sub(coupleId, 'memories').doc(memoryId).delete();
    try { await _storage.refFromURL(url).delete(); } catch (_) {}
  }
}
