import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';

class GratitudeScreen extends StatefulWidget {
  final String coupleId;
  const GratitudeScreen({super.key, required this.coupleId});
  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _saving = false;
  bool _showConfetti = false;
  late AnimationController _enterCtrl;
  late Animation<double> _enterAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);
    _enterCtrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); _enterCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final name = userDoc.data()?['displayName'] ?? 'Partner';
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('gratitude').add({
      'message': _ctrl.text.trim(),
      'from': uid,
      'fromName': name,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
    setState(() { _saving = false; _showConfetti = true; });
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showConfetti = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gratitude Wall')),
      body: Stack(children: [
        const FloatingHearts(count: 8, colors: [AppTheme.dawnAmber, AppTheme.horizonRose]),
        CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              ScaleTransition(scale: _enterAnim, child: _PromptCard(ctrl: _ctrl, onSubmit: _submit, saving: _saving)),
              const SizedBox(height: 24),
            ]),
          )),
          _GratitudeList(coupleId: widget.coupleId),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
        if (_showConfetti) const ConfettiOverlay(),
      ]),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  final bool saving;
  const _PromptCard({required this.ctrl, required this.onSubmit, required this.saving});

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const HeartbeatPulse(child: Text('🙏', style: TextStyle(fontSize: 28))),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today I appreciate you because…', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Fraunces')),
          Text('Stored forever on your gratitude wall', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
      ]),
      const SizedBox(height: 16),
      TextField(
        controller: ctrl,
        maxLines: 4,
        maxLength: 400,
        decoration: const InputDecoration(
          hintText: 'e.g. you made me coffee without me asking, and that\'s love.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      GlowButton(
        label: saving ? 'Saving…' : 'Add to Gratitude Wall 💛',
        icon: Icons.favorite_rounded,
        onTap: saving ? null : onSubmit,
        colors: const [AppTheme.dawnAmber, AppTheme.horizonRose],
      ),
    ]));
  }
}

class _GratitudeList extends StatelessWidget {
  final String coupleId;
  const _GratitudeList({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('gratitude').orderBy('createdAt', descending: true).limit(50).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.dawnAmber))));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('💛', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Your wall is waiting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add your first gratitude above', style: TextStyle(color: AppTheme.textMuted)),
          ]),
        )));
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _GratitudeCard(data: d, index: i);
          }, childCount: docs.length)),
        );
      },
    );
  }
}

class _GratitudeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  const _GratitudeCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = timestamp != null ? DateFormat('MMM d, yyyy').format(timestamp.toDate()) : data['date'] as String? ?? '';
    final colors = [
      [AppTheme.dawnAmber, AppTheme.horizonRose],
      [AppTheme.lavenderDusk, AppTheme.dawnAmber],
      [AppTheme.horizonRose, AppTheme.lavenderDusk],
    ];
    final gradient = colors[index % 3];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text('"${data['message'] ?? ''}"', style: const TextStyle(fontSize: 14, height: 1.6, fontStyle: FontStyle.italic))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('💛 ${data['fromName'] ?? 'Partner'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(dateStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'JetBrains Mono')),
        ]),
      ]),
    );
  }
}
