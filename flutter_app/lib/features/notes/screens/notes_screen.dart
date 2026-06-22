import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
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
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Love Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
          Text('Time-locked letters', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w400)),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE05C7E),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StreamBuilder<List<Note>>(
        stream: repo.notesStream(coupleId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)));
          }
          if (snap.hasError) {
            return _ErrorState(
              error: snap.error.toString(),
              hint: snap.error.toString().contains('index')
                  ? 'Missing Firestore index — check Firebase Console > Indexes for a link to create it.'
                  : null,
            );
          }
          final notes = snap.data ?? [];
          if (notes.isEmpty) return _EmptyState(coupleId: coupleId);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _NoteCard(note: notes[i], coupleId: coupleId, uid: uid, repo: repo),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String coupleId;
  const _EmptyState({required this.coupleId});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💌', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          const Text('No love notes yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Fraunces')),
          const SizedBox(height: 10),
          const Text(
            'Write a note that unlocks on a special day — an anniversary, a birthday, or just because.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Write a Note'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))),
          ),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final String? hint;
  const _ErrorState({required this.error, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 16),
          const Text('Could not load notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(hint ?? error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
        ]),
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
            Icon(
              isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: isUnlocked ? AppTheme.success : const Color(0xFFE05C7E),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(
              isUnlocked ? 'Unlocked ✨' : 'Locked until ${DateFormat('MMM d, yyyy').format(note.openDate)}',
              style: TextStyle(fontSize: 12, color: isUnlocked ? AppTheme.success : AppTheme.textMuted),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isMine ? AppTheme.dawnAmber : const Color(0xFFE05C7E)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isMine ? 'From you' : 'From partner', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ),
          ]),
          const SizedBox(height: 12),
          if (isUnlocked)
            Text(note.text, style: const TextStyle(fontSize: 15, height: 1.65))
          else
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(child: Text('✉️  Opens on unlock date', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
            ),
          if (isUnlocked && !note.opened) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => repo.markOpened(coupleId, note.id),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05C7E)),
                child: const Text('Mark as read 💌'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
