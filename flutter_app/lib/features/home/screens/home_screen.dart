import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/heart_button.dart';
import '../../../core/widgets/petal_bloom_route.dart';
import '../../memories/screens/add_memory_screen.dart';
import '../../notes/screens/add_note_screen.dart';
import '../../garden/screens/garden_screen.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../gratitude/screens/gratitude_screen.dart';
import '../../dreamboard/screens/dreamboard_screen.dart';
import '../../connect/screens/connect_screen.dart';
import '../../gamification/screens/challenges_screen.dart';
import '../../ai/screens/ai_screen.dart';

class HomeScreen extends StatelessWidget {
  final String coupleId;
  const HomeScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    debugPrint('[HomeScreen] build — coupleId=$coupleId uid=$uid');
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Header(coupleId: coupleId),
            _DailySurprise(coupleId: coupleId),
            _ClockRow(),
            _MoodSection(coupleId: coupleId, uid: uid),
            _BatterySection(coupleId: coupleId),
            _StreakSection(coupleId: coupleId),
            _HugButtons(coupleId: coupleId, uid: uid),
            _QuickActions(coupleId: coupleId),
            _FeatureHub(coupleId: coupleId),
            const SizedBox(height: 36),
          ]),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String coupleId;
  const _Header({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          debugPrint('[HomeScreen] header stream error: ${snap.error}');
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final anniversary = (data?['anniversaryDate'] as Timestamp?)?.toDate();
        final days = anniversary != null ? DateTime.now().difference(anniversary).inDays : 0;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HeartSync', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.08)),
                const SizedBox(height: 4),
                snap.connectionState == ConnectionState.waiting
                    ? ShimmerBox(width: 180, height: 28, radius: 6)
                    : Text(
                        anniversary != null ? '$days days together 💕' : 'Welcome home 💕',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: td.primary, fontFamily: 'Fraunces'),
                      ),
              ])),
              HeartbeatPulse(child: const Text('❤️', style: TextStyle(fontSize: 28))),
            ]),
          ),
          HorizonLine(height: 2, colors: [td.primary, td.secondary]),
        ]);
      },
    );
  }
}

// ── Daily Surprise ──────────────────────────────────────────────────────────

class _DailySurprise extends StatefulWidget {
  final String coupleId;
  const _DailySurprise({required this.coupleId});
  @override
  State<_DailySurprise> createState() => _DailySurpriseState();
}

class _DailySurpriseState extends State<_DailySurprise> {
  static final Map<String, int> _seenDay = {};
  bool _revealed = false;
  bool _dismissed = false;

  static const _messages = [
    'Today\'s energy: pure love ☀️', 'You two are doing amazing 💕',
    'Thinking of your partner right now?', 'Every day together is a gift 🎁',
    'Your love story is still being written ✍️', 'Small moments make the biggest memories 📸',
    'Send them a hug — it costs nothing 🤗', 'You make each other better 🌟',
    'Distance is just a number 💌', 'Love grows the more you tend to it 🌸',
    'Today is a great day to say "I love you" 💬', 'You\'re each other\'s home 🏡',
  ];

  bool get _shouldShow => _seenDay[widget.coupleId] != DateTime.now().day && !_dismissed;
  String get _todayMessage => _messages[(DateTime.now().month * 31 + DateTime.now().day) % _messages.length];

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();
    final td = context.watch<ThemeProvider>().data;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _revealed
            ? Container(
                key: const ValueKey('revealed'),
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [td.primary.withValues(alpha: 0.10), td.secondary.withValues(alpha: 0.06)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: td.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_todayMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.45))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 15, color: AppTheme.textMuted),
                    onPressed: () { _seenDay[widget.coupleId] = DateTime.now().day; setState(() => _dismissed = true); },
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ]),
              )
            : GestureDetector(
                key: const ValueKey('gift'),
                onTap: () => setState(() => _revealed = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: td.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: td.border)),
                  child: Row(children: [
                    const Text('🎁', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Daily surprise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Text('Tap to reveal today\'s message', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ])),
                    Icon(Icons.chevron_right, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 16),
                  ]),
                ),
              ),
      ),
    );
  }
}

// ── Clock Row ────────────────────────────────────────────────────────────────

class _ClockRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _ClockBlock(label: 'Your Time', time: _fmt(now)),
          Column(children: [HorizonLine(height: 2), const SizedBox(height: 4), const Text('❤️', style: TextStyle(fontSize: 16))]),
          _ClockBlock(label: "Partner's Time", time: _fmt(now.toUtc().add(const Duration(hours: 2)))),
        ]),
      )),
    );
  }

  String _fmt(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _ClockBlock extends StatelessWidget {
  final String label, time;
  const _ClockBlock({required this.label, required this.time});
  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 3),
      Text(time, style: TextStyle(fontSize: 20, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w700, color: td.primary)),
    ]);
  }
}

// ── Mood ─────────────────────────────────────────────────────────────────────

class _MoodSection extends StatefulWidget {
  final String coupleId, uid;
  const _MoodSection({required this.coupleId, required this.uid});
  @override
  State<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends State<_MoodSection> {
  final _moods = ['😊', '😍', '😔', '🥺', '😤', '🫶'];
  String? _myMood;

  Future<void> _setMood(String mood) async {
    setState(() => _myMood = mood);
    try {
      await FirestoreService().sub(widget.coupleId, 'moods').add({'userId': widget.uid, 'mood': mood, 'timestamp': FieldValue.serverTimestamp()});
      await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
    } catch (e) {
      debugPrint('[HomeScreen] mood write error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save mood: $e'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Today\'s Mood', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((m) => GestureDetector(
              onTap: () => _setMood(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _myMood == m ? td.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _myMood == m ? td.primary : Colors.transparent),
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

// ── Battery ───────────────────────────────────────────────────────────────────

class _BatterySection extends StatelessWidget {
  final String coupleId;
  const _BatterySection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().sub(coupleId, 'battery').doc('current').snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          debugPrint('[HomeScreen] battery stream error: ${snap.error}');
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Text('🔋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Love Battery', style: TextStyle(fontWeight: FontWeight.w600))),
                Text('Offline', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ]),
            )),
          );
        }
        final level = (snap.data?.data() as Map<String, dynamic>?)?['level'] as int? ?? 50;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Love Battery', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$level%', style: TextStyle(fontWeight: FontWeight.w700, color: td.primary, fontSize: 13, fontFamily: 'JetBrains Mono')),
              ]),
              const SizedBox(height: 10),
              HorizonLine(progress: level / 100, height: 8, colors: [td.primary, td.secondary]),
            ]),
          )),
        );
      },
    );
  }
}

// ── Streak ────────────────────────────────────────────────────────────────────

class _StreakSection extends StatelessWidget {
  final String coupleId;
  const _StreakSection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          debugPrint('[HomeScreen] streak stream error: ${snap.error}');
          return const SizedBox.shrink();
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final streak = data?['streak'] as int? ?? 0;
        final isEvening = DateTime.now().hour >= 20;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [td.primary, td.secondary]), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('🔥', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$streak day streak', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const Text('Both act daily to keep it alive', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ])),
              ]),
              if (isEvening && streak > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3))),
                  child: const Row(children: [
                    Text('🌙', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Say good night before today ends to protect your streak 🌙', style: TextStyle(fontSize: 11, color: AppTheme.warning, height: 1.4))),
                  ]),
                ),
              ],
            ]),
          )),
        );
      },
    );
  }
}

// ── Hug Buttons (HeartButton) ────────────────────────────────────────────────

class _HugButtons extends StatelessWidget {
  final String coupleId, uid;
  const _HugButtons({required this.coupleId, required this.uid});

  Future<void> _send(BuildContext context, String type) async {
    try {
      await FirestoreService().sub(coupleId, 'hugs').add({'fromUid': uid, 'type': type, 'sentAt': FieldValue.serverTimestamp()});
      await FirestoreService().updateDailyAction(coupleId, uid);
      if (context.mounted) {
        const msgs = {'hug': 'Hug sent! 🤗', 'kiss': 'Kiss sent! 💋', 'miss': 'Miss you sent! 💭'};
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msgs[type] ?? 'Sent!'), backgroundColor: AppTheme.horizonRose, duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      debugPrint('[HomeScreen] hug send error: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          const Text('Send', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            HeartButton(size: 64, color: td.primary, label: 'Hug', onPressed: () => _send(context, 'hug'), child: const Text('🤗', style: TextStyle(fontSize: 26))),
            HeartButton(size: 64, color: td.secondary, label: 'Kiss', onPressed: () => _send(context, 'kiss'), child: const Text('💋', style: TextStyle(fontSize: 26))),
            HeartButton(size: 64, color: AppTheme.lavenderDusk, label: 'Miss You', onPressed: () => _send(context, 'miss'), child: const Text('💭', style: TextStyle(fontSize: 26))),
          ]),
        ]),
      )),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final String coupleId;
  const _QuickActions({required this.coupleId});
  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: _ActionCard(icon: Icons.add_photo_alternate_outlined, label: 'Add Memory', color: td.primary,
          onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))))),
        const SizedBox(width: 12),
        Expanded(child: _ActionCard(icon: Icons.note_add_outlined, label: 'Love Note', color: td.secondary,
          onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))))),
      ]),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  State<_ActionCard> createState() => _ActionCardState();
}
class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(scale: _pressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 100),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.color.withValues(alpha: 0.25))),
        child: Column(children: [
          Icon(widget.icon, color: widget.color, size: 26),
          const SizedBox(height: 8),
          Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.color)),
        ]),
      ),
    ),
  );
}

// ── Feature Hub ───────────────────────────────────────────────────────────────

class _FeatureHub extends StatefulWidget {
  final String coupleId;
  const _FeatureHub({required this.coupleId});
  @override
  State<_FeatureHub> createState() => _FeatureHubState();
}

class _FeatureHubState extends State<_FeatureHub> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _fades, _scales;

  List<_Feature> get _features => [
    _Feature('🌿', 'Garden',      const Color(0xFF4ADE80), (ctx) => GardenScreen(coupleId: widget.coupleId)),
    _Feature('📖', 'Our Story',   AppTheme.lavenderDusk,   (ctx) => MilestonesScreen(coupleId: widget.coupleId)),
    _Feature('🙏', 'Gratitude',   AppTheme.horizonRose,    (ctx) => GratitudeScreen(coupleId: widget.coupleId)),
    _Feature('🌟', 'Dream Board', AppTheme.lavenderDusk,   (ctx) => DreamBoardScreen(coupleId: widget.coupleId)),
    _Feature('💬', 'Connect',     AppTheme.dawnAmber,      (ctx) => ConnectScreen(coupleId: widget.coupleId)),
    _Feature('🏆', 'Challenges',  AppTheme.warning,        (ctx) => ChallengesScreen(coupleId: widget.coupleId)),
    _Feature('✨', 'AI Features', const Color(0xFFE05C7E), (ctx) => AiScreen(coupleId: widget.coupleId)),
  ];

  @override
  void initState() {
    super.initState();
    final n = _features.length;
    _ctrls  = List.generate(n, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 360)));
    _fades  = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _scales = _ctrls.map((c) => Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    for (int i = 0; i < n; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 65), () { if (mounted) _ctrls[i].forward(); });
    }
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final features = _features;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Text('Everything for you two', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.01)),
      ),
      SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: features.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => FadeTransition(
            opacity: _fades[i],
            child: ScaleTransition(
              scale: _scales[i],
              child: _FeatureCard(feature: features[i]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _Feature {
  final String emoji, label;
  final Color color;
  final Widget Function(BuildContext) builder;
  const _Feature(this.emoji, this.label, this.color, this.builder);
}

class _FeatureCard extends StatefulWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}
class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); Navigator.push(context, petalBloomRoute(builder: f.builder)); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(scale: _pressed ? 0.93 : 1.0, duration: const Duration(milliseconds: 100),
        child: Container(width: 96,
          decoration: BoxDecoration(
            color: f.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: f.color.withValues(alpha: 0.28)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: f.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(f.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 8),
            Text(f.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: f.color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
