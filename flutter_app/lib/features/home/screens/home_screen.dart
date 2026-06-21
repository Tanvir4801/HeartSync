import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firestore_service.dart';
import '../../memories/screens/add_memory_screen.dart';
import '../../notes/screens/add_note_screen.dart';

class HomeScreen extends StatelessWidget {
  final String coupleId;
  const HomeScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(coupleId: coupleId)),
            SliverToBoxAdapter(child: _MoodSection(coupleId: coupleId, uid: uid)),
            SliverToBoxAdapter(child: _BatterySection(coupleId: coupleId)),
            SliverToBoxAdapter(child: _StreakSection(coupleId: coupleId)),
            SliverToBoxAdapter(child: _HugButton(coupleId: coupleId, uid: uid)),
            SliverToBoxAdapter(child: _QuickActions(coupleId: coupleId, context: context)),
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
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HeartSync', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.favorite, color: Color(0xFFE05C7E), size: 18),
              const SizedBox(width: 6),
              Text('$days days together', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF0F0F6))),
            ]),
          ]),
        );
      },
    );
  }
}

class _MoodSection extends StatefulWidget {
  final String coupleId;
  final String uid;
  const _MoodSection({required this.coupleId, required this.uid});
  @override
  State<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends State<_MoodSection> {
  final moods = ['😊', '😍', '😔', '🥺'];
  String? _myMood;

  Future<void> _setMood(String mood) async {
    setState(() => _myMood = mood);
    await FirestoreService().sub(widget.coupleId, 'moods').add({
      'userId': widget.uid,
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Today\'s Mood', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: moods.map((m) => GestureDetector(
                onTap: () => _setMood(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _myMood == m ? const Color(0xFFE05C7E).withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _myMood == m ? const Color(0xFFE05C7E) : Colors.transparent),
                  ),
                  child: Text(m, style: const TextStyle(fontSize: 30)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2E2E3E)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().sub(widget.coupleId, 'moods')
                  .orderBy('timestamp', descending: true).limit(2).snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Text('No moods yet today', style: TextStyle(color: Color(0xFF8888A8), fontSize: 12));
                return Wrap(
                  spacing: 8,
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return Chip(
                      label: Text(data['mood'] ?? '', style: const TextStyle(fontSize: 16)),
                      backgroundColor: const Color(0xFF23232F),
                    );
                  }).toList(),
                );
              },
            ),
          ]),
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Love Battery', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$level%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE05C7E))),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: level / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF23232F),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      level > 60 ? const Color(0xFF4ADE80) : level > 30 ? const Color(0xFFFACC15) : const Color(0xFFF87171),
                    ),
                  ),
                ),
              ]),
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$streak day streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Keep going! Both act daily to extend it.', style: TextStyle(color: Color(0xFF8888A8), fontSize: 12)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _HugButton extends StatefulWidget {
  final String coupleId;
  final String uid;
  const _HugButton({required this.coupleId, required this.uid});
  @override
  State<_HugButton> createState() => _HugButtonState();
}

class _HugButtonState extends State<_HugButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _sendHug() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    await FirestoreService().sub(widget.coupleId, 'hugs').add({
      'fromUid': widget.uid,
      'sentAt': FieldValue.serverTimestamp(),
    });
    await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hug sent! ❤️'), backgroundColor: Color(0xFFE05C7E), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('Virtual Hug', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _sendHug,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE05C7E), Color(0xFFC04060)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: const Color(0xFFE05C7E).withOpacity(0.4), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to send a hug', style: TextStyle(color: Color(0xFF8888A8), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String coupleId;
  final BuildContext context;
  const _QuickActions({required this.coupleId, required this.context});

  @override
  Widget build(BuildContext outerCtx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _ActionCard(icon: Icons.add_photo_alternate_outlined, label: 'Add Memory', onTap: () => Navigator.push(outerCtx, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))))),
        const SizedBox(width: 12),
        Expanded(child: _ActionCard(icon: Icons.note_add_outlined, label: 'Love Note', onTap: () => Navigator.push(outerCtx, MaterialPageRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))))),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: const Color(0xFFE05C7E), size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
