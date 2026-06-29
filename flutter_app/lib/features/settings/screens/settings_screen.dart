import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/petal_bloom_route.dart';
import '../../themes/screens/theme_picker_screen.dart';

const kVaultPinKey = 'hs_vault_pin';

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
          _Tile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => _editProfileSheet(context)),
          _Tile(icon: Icons.palette_outlined, label: 'Couple Theme', onTap: () {
            Navigator.push(context, petalBloomRoute(builder: (_) => const ThemePickerScreen()));
          }),
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
          _Tile(icon: Icons.info_outline, label: 'Privacy Policy', onTap: () => _showPolicy(context, 'Privacy Policy', _privacyPolicyText)),
          _Tile(icon: Icons.article_outlined, label: 'Terms of Service', onTap: () => _showPolicy(context, 'Terms of Service', _tosText)),
          const SizedBox(height: 20),
          _Tile(icon: Icons.logout, label: 'Sign Out', onTap: () => FirebaseAuth.instance.signOut(), textColor: AppTheme.danger),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _editProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _EditProfileSheet(),
    );
  }

  void _changePinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ChangePinSheet(),
    );
  }

  void _supportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SupportTicketSheet(),
    );
  }

  void _gdprSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GdprRequestSheet(type: type),
    );
  }

  void _showPolicy(BuildContext context, String title, String text) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PolicySheet(title: title, text: text),
    );
  }
}

// ── Policy Sheet ──────────────────────────────────────────────────────────────

class _PolicySheet extends StatelessWidget {
  final String title, text;
  const _PolicySheet({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (_, ctrl) => Column(children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        const Divider(),
        Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
          Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.7)),
        ])),
      ]),
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  bool _saved  = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(_nameCtrl.text.trim());
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      setState(() => _saved = true);
    } catch (e) {
      debugPrint('[EditProfile] error: $e');
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: _saved
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Profile updated!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              const SizedBox(height: 20),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Changes are visible to your partner.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 8),
              Text(FirebaseAuth.instance.currentUser?.email ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 20),
              _saving
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber))
                  : ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
              const SizedBox(height: 20),
            ]),
    );
  }
}

// ── Section Header / Tile ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.08, color: AppTheme.textMuted)),
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

// ── Support Ticket Sheet ──────────────────────────────────────────────────────

class _SupportTicketSheet extends StatefulWidget {
  const _SupportTicketSheet();
  @override State<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends State<_SupportTicketSheet> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _sent    = false;

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'message':    _msgCtrl.text.trim(),
        'userEmail':  user?.email,
        'userId':     user?.uid,
        'status':     'open',
        'createdAt':  FieldValue.serverTimestamp(),
      });
      setState(() => _sent = true);
    } catch (_) {}
    setState(() => _sending = false);
  }

  @override void dispose() { _msgCtrl.dispose(); super.dispose(); }

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
              _sending
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber))
                  : ElevatedButton(onPressed: _submit, child: const Text('Send to Support')),
              const SizedBox(height: 20),
            ]),
    );
  }
}

// ── GDPR Sheet ────────────────────────────────────────────────────────────────

class _GdprRequestSheet extends StatefulWidget {
  final String type;
  const _GdprRequestSheet({required this.type});
  @override State<_GdprRequestSheet> createState() => _GdprRequestSheetState();
}

class _GdprRequestSheetState extends State<_GdprRequestSheet> {
  bool _sending = false;
  bool _sent    = false;

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final coupleId = snapshot.data()?['coupleId'] ?? 'unknown';
      await FirebaseFirestore.instance.collection('admin').doc('data_requests').collection('items').add({
        'coupleId':    coupleId,
        'type':        widget.type,
        'status':      'pending',
        'requestedBy': user?.uid,
        'requestedAt': FieldValue.serverTimestamp(),
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
              const Text('Our team will process your request within 30 days.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              const SizedBox(height: 20),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isDeletion ? 'Delete My Account' : 'Request My Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDeletion ? AppTheme.danger : null)),
              const SizedBox(height: 12),
              if (isDeletion)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: const Text('This will permanently delete all your couple data, memories, messages, and photos. This cannot be undone.', style: TextStyle(fontSize: 13, color: AppTheme.danger, height: 1.5)),
                ),
              if (!isDeletion)
                const Text('We will prepare an export of all your couple data and notify you when it is ready.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              _sending
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber))
                  : ElevatedButton(
                      onPressed: _submit,
                      style: isDeletion ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger) : null,
                      child: Text(isDeletion ? 'Request Deletion' : 'Request Export'),
                    ),
              const SizedBox(height: 20),
            ]),
    );
  }
}

// ── Change PIN Sheet ──────────────────────────────────────────────────────────

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();
  @override State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _error   = false;
  bool _saving  = false;

  Future<void> _save() async {
    if (_newCtrl.text.length < 4) { setState(() => _error = true); return; }
    if (_newCtrl.text != _confirmCtrl.text) { setState(() => _error = true); return; }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kVaultPinKey, _newCtrl.text);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated 🔐'), backgroundColor: Color(0xFF4CAF50)));
  }

  @override void dispose() { _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Change Vault PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('PIN must be 4–6 digits. Used to lock your Love Vault.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(controller: _newCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'New PIN (4–6 digits)', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 10),
        TextField(controller: _confirmCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'Confirm PIN', errorText: _error ? 'PINs do not match or too short' : null, prefixIcon: const Icon(Icons.lock_outline))),
        const SizedBox(height: 20),
        _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : ElevatedButton(onPressed: _save, child: const Text('Save PIN')),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Policy Text ───────────────────────────────────────────────────────────────

const _privacyPolicyText = '''
HeartSync Privacy Policy

Last updated: June 2025

1. Data We Collect
We collect the data you and your partner provide: profile information, messages, memories (photos, notes), mood check-ins, and couple activity. Firebase Analytics collects anonymized usage data.

2. How We Use It
Your couple data is stored securely in Firebase Firestore with industry-standard security rules. We never sell your data. AI features (love letters, captions) use the Gemini API — prompts are not stored by Google for training beyond the request.

3. Data Sharing
We do not share your personal data with third parties, except:
• Firebase (Google) for hosting and authentication
• RevenueCat for subscription management
• Google Gemini for AI generation (ephemeral, no training)

4. Data Deletion
You may request deletion at any time via Settings → Delete My Account. This permanently removes all couple data, memories, messages, and photos.

5. Security
All data is encrypted in transit (TLS) and at rest. Love Vault contents are client-side encrypted before upload.

6. Contact
For questions, contact support via the app's Contact Support option.
''';

const _tosText = '''
HeartSync Terms of Service

Last updated: June 2025

1. Acceptance
By using HeartSync, you agree to these terms. If you do not agree, do not use the app.

2. Eligibility
You must be 18 years or older to use HeartSync. The app is designed for romantic couples.

3. Acceptable Use
Do not use HeartSync to share illegal, harmful, or abusive content. Do not share another user's private data without consent.

4. Couple Space
Your couple space is a shared environment. Both partners have equal access to shared content within the space.

5. Premium Features
Premium features are available via subscription. Subscriptions auto-renew unless cancelled. Refund policies are governed by the App Store/Google Play.

6. AI Features
AI-generated content (love letters, captions) is for personal use. AI responses may occasionally be inaccurate.

7. Termination
We may terminate accounts that violate these terms. You may delete your account at any time via Settings.

8. Disclaimer
HeartSync is provided "as is". We are not liable for relationship outcomes or data loss beyond our reasonable control.

9. Contact
contact@heartsync.app
''';
