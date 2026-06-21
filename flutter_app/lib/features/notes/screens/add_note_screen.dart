import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../repository/note_repository.dart';

class AddNoteScreen extends StatefulWidget {
  final String coupleId;
  const AddNoteScreen({super.key, required this.coupleId});
  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _textCtrl = TextEditingController();
  final _repo = NoteRepository();
  DateTime _openDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  Future<void> _pickOpenDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _openDate,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (d != null) setState(() => _openDate = d);
  }

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final note = Note(
        id: '', text: _textCtrl.text.trim(),
        authorId: uid, openDate: _openDate,
        opened: false, createdAt: DateTime.now(),
      );
      await _repo.addNote(widget.coupleId, note);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF87171)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write Love Note'), actions: [
        _loading
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFE05C7E), strokeWidth: 2)))
            : TextButton(onPressed: _save, child: const Text('Send 💌', style: TextStyle(color: Color(0xFFE05C7E), fontWeight: FontWeight.w600))),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Write your note', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: null, expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: 'Pour your heart out…', alignLabelWithHint: true),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Unlock date', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickOpenDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E2E3E))),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: Color(0xFFE05C7E), size: 18),
                const SizedBox(width: 10),
                Text(DateFormat('MMMM d, yyyy').format(_openDate), style: const TextStyle(color: Color(0xFFF0F0F6))),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Color(0xFF8888A8)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text('Your partner will see a locked card until ${DateFormat('MMMM d').format(_openDate)}.', style: const TextStyle(color: Color(0xFF8888A8), fontSize: 12)),
        ]),
      ),
    );
  }
}
