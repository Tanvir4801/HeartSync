import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _pinCtrl = TextEditingController();
  bool _unlocked = false;
  bool _error = false;
  static const _pin = '1234';

  void _submit() {
    if (_pinCtrl.text == _pin) {
      setState(() { _unlocked = true; _error = false; });
    } else {
      setState(() => _error = true);
      _pinCtrl.clear();
    }
  }

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
          Container(width: 80, height: 80, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.dawnAmber, AppTheme.horizonRose]), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.lock, color: Colors.white, size: 36)),
          const SizedBox(height: 24),
          const Text('Love Vault', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
          const SizedBox(height: 8),
          const Text('PIN-protected private space.\nOnly you and your partner can access this.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, height: 1.5)),
          const SizedBox(height: 8),
          const Text('Vault contents are client-side encrypted.\nRegular memories use Firestore security rules — not end-to-end encrypted.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.5)),
          const SizedBox(height: 32),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12, fontFamily: 'JetBrains Mono'),
            decoration: InputDecoration(
              hintText: '• • • •',
              counterText: '',
              errorText: ctrl.text.isNotEmpty && error ? 'Incorrect PIN' : null,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onSubmit, child: const Text('Unlock Vault')),
          const SizedBox(height: 12),
          Text('Default PIN: 1234 — change in Settings', style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 11)),
        ]),
      ),
    );
  }
}

class _VaultContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Icon(Icons.lock_open, size: 16, color: AppTheme.dawnAmber), const SizedBox(width: 6), const Text('Love Vault — Unlocked')]),
        actions: [IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: () {}, tooltip: 'Add to Vault')],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.dawnAmber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dawnAmber.withValues(alpha: 0.2))),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.dawnAmber),
              SizedBox(width: 8),
              Expanded(child: Text('Contents added here are encrypted before upload. They never appear in your main memory timeline or search results.', style: TextStyle(fontSize: 12, color: AppTheme.dawnAmber, height: 1.5))),
            ])),
          const SizedBox(height: 24),
          const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🔐', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Your vault is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Add private photos and notes only you two can see', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
          ]))),
        ]),
      ),
    );
  }
}
