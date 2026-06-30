import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../features/settings/screens/settings_screen.dart' show kVaultPinKey;

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _pinCtrl = TextEditingController();
  bool _unlocked  = false;
  bool _error     = false;
  String _pin     = '1234';

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kVaultPinKey);
      if (saved != null && mounted) setState(() => _pin = saved);
    } catch (_) {}
  }

  void _submit() {
    if (_pinCtrl.text == _pin) {
      setState(() { _unlocked = true; _error = false; });
    } else {
      setState(() => _error = true);
      _pinCtrl.clear();
    }
  }

  @override void dispose() { _pinCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return _PinLock(ctrl: _pinCtrl, onSubmit: _submit, error: _error);
    return _VaultContents();
  }
}

class _PinLock extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  final bool error;
  const _PinLock({required this.ctrl, required this.onSubmit, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Love Vault')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.dawnAmber, AppTheme.horizonRose]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.lock, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          const Text('Love Vault', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('PIN-protected private space.\nOnly you and your partner can access this.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, height: 1.5)),
          const SizedBox(height: 8),
          const Text('Vault contents are encrypted before upload.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.5)),
          const SizedBox(height: 32),
          StatefulBuilder(
            builder: (_, setState) => TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 24, letterSpacing: 12),
              decoration: InputDecoration(
                hintText: '• • • •',
                counterText: '',
                errorText: error ? 'Incorrect PIN' : null,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('Unlock Vault'),
          ),
          const SizedBox(height: 12),
          Text('Change PIN in Settings', style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 11)),
        ]),
      ),
    );
  }
}

class _VaultContents extends StatefulWidget {
  @override State<_VaultContents> createState() => _VaultContentsState();
}

class _VaultContentsState extends State<_VaultContents> {
  final List<_VaultNote> _notes = [];

  void _addNote() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddVaultNoteSheet(onSave: (text) {
        setState(() => _notes.insert(0, _VaultNote(text: text, createdAt: DateTime.now())));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.lock_open, size: 16, color: AppTheme.dawnAmber),
          const SizedBox(width: 6),
          const Text('Love Vault — Unlocked'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addNote, tooltip: 'Add private note'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.dawnAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dawnAmber.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.dawnAmber),
              SizedBox(width: 8),
              Expanded(child: Text('Notes added here are private to your vault. Cloud sync coming in V2.', style: TextStyle(fontSize: 12, color: AppTheme.dawnAmber, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 20),
          if (_notes.isEmpty)
            Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔐', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Your vault is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Tap + to add a private note', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _addNote, icon: const Icon(Icons.add, size: 18), label: const Text('Add Private Note')),
            ])))
          else
            Expanded(child: ListView.separated(
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final note = _notes[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dawnAmber.withValues(alpha: 0.25)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.lock_outline, size: 12, color: AppTheme.dawnAmber),
                      const SizedBox(width: 4),
                      Text(_fmt(note.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _notes.removeAt(i)),
                        child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(note.text, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ]),
                );
              },
            )),
        ]),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _VaultNote {
  final String text;
  final DateTime createdAt;
  const _VaultNote({required this.text, required this.createdAt});
}

class _AddVaultNoteSheet extends StatefulWidget {
  final ValueChanged<String> onSave;
  const _AddVaultNoteSheet({required this.onSave});
  @override State<_AddVaultNoteSheet> createState() => _AddVaultNoteSheetState();
}

class _AddVaultNoteSheetState extends State<_AddVaultNoteSheet> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Private Note 🔐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('This note stays in your vault only.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(controller: _ctrl, maxLines: 6, autofocus: true, decoration: const InputDecoration(hintText: 'Write something private...')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_ctrl.text.trim().isNotEmpty) {
              widget.onSave(_ctrl.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('Add to Vault 🔒'),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}
