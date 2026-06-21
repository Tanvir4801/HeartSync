import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../repository/note_repository.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatelessWidget {
  final String coupleId;
  const NotesScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final repo = NoteRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Love Notes')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE05C7E),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StreamBuilder<List<Note>>(
        stream: repo.notesStream(coupleId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)));
          final notes = snap.data ?? [];
          if (notes.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('💌', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text('No love notes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Write a note that unlocks on a special day', style: TextStyle(color: Color(0xFF8888A8))),
          ]));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _NoteCard(note: notes[i], coupleId: coupleId, uid: uid, repo: repo),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final String coupleId;
  final String uid;
  final NoteRepository repo;
  const _NoteCard({required this.note, required this.coupleId, required this.uid, required this.repo});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = note.isUnlocked;
    final isMine = note.authorId == uid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isUnlocked ? Icons.lock_open : Icons.lock, color: isUnlocked ? const Color(0xFF4ADE80) : const Color(0xFFE05C7E), size: 16),
            const SizedBox(width: 6),
            Text(isUnlocked ? 'Unlocked' : 'Locked until ${DateFormat('MMM d, yyyy').format(note.openDate)}',
                style: TextStyle(fontSize: 12, color: isUnlocked ? const Color(0xFF4ADE80) : const Color(0xFF8888A8))),
            const Spacer(),
            Text(isMine ? 'From you' : 'From partner', style: const TextStyle(fontSize: 11, color: Color(0xFF8888A8))),
          ]),
          const SizedBox(height: 12),
          if (isUnlocked)
            Text(note.text, style: const TextStyle(fontSize: 15, height: 1.6))
          else
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF23232F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('✉️ Tap to peek when it unlocks', style: TextStyle(color: Color(0xFF8888A8), fontSize: 13))),
            ),
          if (isUnlocked && !note.opened) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => repo.markOpened(coupleId, note.id),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C7E)),
              child: const Text('Mark as read 💌'),
            )),
          ],
        ]),
      ),
    );
  }
}
