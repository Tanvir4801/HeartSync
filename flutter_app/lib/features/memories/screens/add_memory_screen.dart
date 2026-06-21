import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memory_model.dart';
import '../repository/memory_repository.dart';

class AddMemoryScreen extends StatefulWidget {
  final String coupleId;
  const AddMemoryScreen({super.key, required this.coupleId});
  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _captionCtrl = TextEditingController();
  final _repo = MemoryRepository();
  File? _file;
  bool _loading = false;
  DateTime _date = DateTime.now();
  String _type = 'photo';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() { _file = File(picked.path); _type = 'photo'; });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2000), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_captionCtrl.text.trim().isEmpty && _file == null) return;
    setState(() => _loading = true);
    try {
      String url = '';
      if (_file != null) {
        url = await _repo.uploadMedia(widget.coupleId, _file!, _type);
      }
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final memory = Memory(
        id: '', type: _type, url: url,
        caption: _captionCtrl.text.trim(),
        date: _date,
      );
      await _repo.addMemory(widget.coupleId, memory);
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
      appBar: AppBar(title: const Text('Add Memory'), actions: [
        if (_loading) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFE05C7E), strokeWidth: 2)))
        else TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: Color(0xFFE05C7E), fontWeight: FontWeight.w600))),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF23232F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E2E3E)),
              ),
              child: _file != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_file!, fit: BoxFit.cover))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFE05C7E)),
                      SizedBox(height: 8),
                      Text('Tap to add photo', style: TextStyle(color: Color(0xFF8888A8))),
                    ]),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Caption', hintText: 'Describe this moment…', alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E2E3E))),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: Color(0xFFE05C7E), size: 18),
                const SizedBox(width: 10),
                Text('${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: Color(0xFFF0F0F6))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
