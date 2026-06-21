import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firestore_service.dart';
import '../../../core/theme.dart';
import '../../memories/screens/add_memory_screen.dart';
import '../../notes/screens/add_note_screen.dart';

class HomeScreen extends StatelessWidget {
  final String coupleId;
  const HomeScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.duskIndigo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(coupleId: coupleId)),
            SliverToBoxAdapter(child: _ClockRow()),
            SliverToBoxAdapter(child: _MoodSection(coupleId: coupleId, uid: uid)),
            SliverToBoxAdapter(child: _BatterySection(coupleId: coupleId)),
            SliverToBoxAdapter(child: _StreakSection(coupleId: coupleId)),
            SliverToBoxAdapter(child: _HugButtons(coupleId: coupleId, uid: uid)),
            SliverToBoxAdapter(child: _QuickActions(coupleId: coupleId)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String coupleId;
  const _Header({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final anniversary = (data?['anniversaryDate'] as Timestamp?)?.toDate();
        final days = anniversary != null ? DateTime.now().difference(anniversary).inDays : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HeartSync', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.06)),
                const SizedBox(height: 4),
                Text('$days days together', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.dawnAmber, fontFamily: 'Fraunces')),
              ]),
            ),
            const HorizonLine(height: 2),
          ],
        );
      },
    );
  }
}

class _ClockRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final utc = now.toUtc();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _ClockBlock(label: 'Your Time', time: _fmt(now)),
              Column(children: [
                const HorizonLine(height: 2),
                const SizedBox(height: 6),
                const Text('❤️', style: TextStyle(fontSize: 18)),
              ]),
              _ClockBlock(label: "Partner's Time", time: _fmt(utc.add(const Duration(hours: 2)))),
            ]),
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _ClockBlock extends StatelessWidget {
  final String label;
  final String time;
  const _ClockBlock({required this.label, required this.time});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
    const SizedBox(height: 4),
    Text(time, style: const TextStyle(fontSize: 22, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w700, color: AppTheme.dawnAmber)),
  ]);
}

class _MoodSection extends StatefulWidget {
  final String coupleId;
  final String uid;
  const _MoodSection({required this.coupleId, required this.uid});
  @override
  State<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends State<_MoodSection> {
  final moods = ['😊', '😍', '😔', '🥺', '😤', '🫶'];
  String? _myMood;

  Future<void> _setMood(String mood) async {
    setState(() => _myMood = mood);
    await FirestoreService().sub(widget.coupleId, 'moods').add({
      'userId': widget.uid, 'mood': mood, 'timestamp': FieldValue.serverTimestamp(),
    });
    await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Today\'s Mood', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((m) => GestureDetector(
              onTap: () => _setMood(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _myMood == m ? AppTheme.dawnAmber.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _myMood == m ? AppTheme.dawnAmber : Colors.transparent),
                ),
                child: Text(m, style: const TextStyle(fontSize: 26)),
              ),
            )).toList(),
          ),
        ]),
      )),
    );
  }
}

class _BatterySection extends StatelessWidget {
  final String coupleId;
  const _BatterySection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().sub(coupleId, 'battery').doc('current').snapshots(),
      builder: (_, snap) {
        final level = (snap.data?.data() as Map<String, dynamic>?)?['level'] as int? ?? 50;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Love Battery', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$level%', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.dawnAmber, fontFamily: 'JetBrains Mono')),
              ]),
              const SizedBox(height: 12),
              HorizonLine(progress: level / 100, height: 8),
            ]),
          )),
        );
      },
    );
  }
}

class _StreakSection extends StatelessWidget {
  final String coupleId;
  const _StreakSection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final streak = data?['streak'] as int? ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.dawnAmber, AppTheme.horizonRose]), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('🔥', style: TextStyle(fontSize: 22)))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$streak day streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('Both act daily to keep it going', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ]),
            ]),
          )),
        );
      },
    );
  }
}

class _HugButtons extends StatefulWidget {
  final String coupleId;
  final String uid;
  const _HugButtons({required this.coupleId, required this.uid});
  @override
  State<_HugButtons> createState() => _HugButtonsState();
}

class _HugButtonsState extends State<_HugButtons> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send(String type) async {
    await _ctrl.forward();
    await _ctrl.reverse();
    await FirestoreService().sub(widget.coupleId, 'hugs').add({
      'fromUid': widget.uid, 'type': type, 'sentAt': FieldValue.serverTimestamp(),
    });
    await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
    if (mounted) {
      final msgs = {'hug': 'Hug sent! 🤗', 'miss': 'Miss you sent! 💭', 'emergency': 'Emergency hug sent! 🆘'};
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msgs[type] ?? 'Sent!'), backgroundColor: AppTheme.dawnAmber, duration: const Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Send', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _HugBtn(emoji: '🤗', label: 'Hug', color: AppTheme.dawnAmber, scale: _scale, onTap: () => _send('hug')),
            _HugBtn(emoji: '💭', label: 'Miss You', color: AppTheme.horizonRose, scale: _scale, onTap: () => _send('miss')),
            _HugBtn(emoji: '🆘', label: 'Need You', color: AppTheme.lavenderDusk, scale: _scale, onTap: () => _send('emergency')),
          ]),
        ]),
      )),
    );
  }
}

class _HugBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Animation<double> scale;
  final VoidCallback onTap;
  const _HugBtn({required this.emoji, required this.label, required this.color, required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ScaleTransition(scale: scale, child: Column(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
    ])),
  );
}

class _QuickActions extends StatelessWidget {
  final String coupleId;
  const _QuickActions({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(child: _ActionCard(icon: Icons.add_photo_alternate_outlined, label: 'Add Memory', color: AppTheme.dawnAmber,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))))),
        const SizedBox(width: 12),
        Expanded(child: _ActionCard(icon: Icons.note_add_outlined, label: 'Love Note', color: AppTheme.horizonRose,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))))),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
