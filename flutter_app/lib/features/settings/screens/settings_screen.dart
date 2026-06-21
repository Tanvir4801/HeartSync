import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('Account'),
          _Tile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
          _Tile(icon: Icons.palette_outlined, label: 'Couple Theme', onTap: () {}),
          _Tile(icon: Icons.lock_outline, label: 'Change PIN', onTap: () => _changePinSheet(context)),
          const SizedBox(height: 20),
          _SectionHeader('Support'),
          _Tile(icon: Icons.headset_mic_outlined, label: 'Contact Support', onTap: () => _supportSheet(context)),
          const SizedBox(height: 20),
          _SectionHeader('Privacy & Data'),
          _Tile(icon: Icons.download_outlined, label: 'Request My Data', onTap: () => _gdprSheet(context, 'export')),
          _Tile(icon: Icons.delete_forever_outlined, label: 'Delete My Account', onTap: () => _gdprSheet(context, 'deletion'), textColor: AppTheme.danger),
          const SizedBox(height: 20),
          _SectionHeader('About'),
          _Tile(icon: Icons.info_outline, label: 'Privacy Policy', onTap: () {}),
          _Tile(icon: Icons.article_outlined, label: 'Terms of Service', onTap: () {}),
          const SizedBox(height: 20),
          _Tile(icon: Icons.logout, label: 'Sign Out', onTap: () => FirebaseAuth.instance.signOut(), textColor: AppTheme.danger),
        ],
      ),
    );
  }

  void _changePinSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ChangePinSheet());
  }

  void _supportSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SupportTicketSheet());
  }

  void _gdprSheet(BuildContext context, String type) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GdprRequestSheet(type: type));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.08, color: AppTheme.textMuted, textBaseline: TextBaseline.alphabetic)),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  const _Tile({required this.icon, required this.label, required this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: textColor ?? AppTheme.textMuted),
    title: Text(label, style: TextStyle(fontSize: 14, color: textColor ?? AppTheme.textPrimary)),
    trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

class _SupportTicketSheet extends StatefulWidget {
  const _SupportTicketSheet();
  @override
  State<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends State<_SupportTicketSheet> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'message': _msgCtrl.text.trim(),
        'userEmail': user?.email,
        'userId': user?.uid,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _sent = true);
    } catch (_) {}
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: _sent
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Ticket submitted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text("We'll get back to you within 24 hours.", style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              const SizedBox(height: 20),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Contact Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Describe your issue and our team will reply in the app.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(controller: _msgCtrl, maxLines: 5, decoration: const InputDecoration(hintText: 'What can we help you with?')),
              const SizedBox(height: 16),
              _sending ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : ElevatedButton(onPressed: _submit, child: const Text('Send to Support')),
              const SizedBox(height: 20),
            ]),
    );
  }
}

class _GdprRequestSheet extends StatefulWidget {
  final String type;
  const _GdprRequestSheet({required this.type});
  @override
  State<_GdprRequestSheet> createState() => _GdprRequestSheetState();
}

class _GdprRequestSheetState extends State<_GdprRequestSheet> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final coupleId = snapshot.data()?['coupleId'] ?? 'unknown';
      await FirebaseFirestore.instance.collection('admin').doc('data_requests').collection('items').add({
        'coupleId': coupleId, 'type': widget.type, 'status': 'pending',
        'requestedBy': user?.uid, 'requestedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _sent = true);
    } catch (_) {}
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDeletion = widget.type == 'deletion';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: _sent
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Text(isDeletion ? '🗑' : '📦', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(isDeletion ? 'Deletion requested' : 'Export requested', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text("Our team will process your request within 30 days.", style: TextStyle(color: AppTheme.textMuted, textAlign: TextAlign.center)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              const SizedBox(height: 20),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isDeletion ? 'Delete My Account' : 'Request My Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDeletion ? AppTheme.danger : null)),
              const SizedBox(height: 12),
              if (isDeletion) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                child: const Text('This will permanently delete all your couple data, memories, messages, and photos. This cannot be undone.', style: TextStyle(fontSize: 13, color: AppTheme.danger, height: 1.5))),
              if (!isDeletion) const Text('We will prepare an export of all your couple data and notify you when it is ready.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              _sending ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : ElevatedButton(
                onPressed: _submit,
                style: isDeletion ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger) : null,
                child: Text(isDeletion ? 'Request Deletion' : 'Request Export'),
              ),
              const SizedBox(height: 20),
            ]),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();
  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _error = false;

  void _save() {
    if (_newCtrl.text.length < 4) { setState(() => _error = true); return; }
    if (_newCtrl.text != _confirmCtrl.text) { setState(() => _error = true); return; }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Change PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _newCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'New PIN (4–6 digits)')),
        const SizedBox(height: 10),
        TextField(controller: _confirmCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'Confirm PIN', errorText: _error ? 'PINs do not match or too short' : null)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _save, child: const Text('Save PIN')),
        const SizedBox(height: 20),
      ]),
    );
  }
}
