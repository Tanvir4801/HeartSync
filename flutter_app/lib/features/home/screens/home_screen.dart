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
    debugPrint('[HomeScreen] build coupleId=$coupleId uid=$uid');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Scaffold(
        backgroundColor: td.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(coupleId: coupleId),
                _DailySurprise(coupleId: coupleId),
                _ClockRow(),
                _MoodSection(coupleId: coupleId, uid: uid),
                _BatterySection(coupleId: coupleId),
                _StreakSection(coupleId: coupleId),
                _HugButtons(coupleId: coupleId, uid: uid),
                _QuickActions(coupleId: coupleId),
                _FeatureHub(coupleId: coupleId),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[HomeScreen] TOP-LEVEL BUILD ERROR: $e\n$s');
      return Scaffold(
        backgroundColor: AppTheme.duskIndigo,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('HomeScreen error: $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
        )),
      );
    }
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String coupleId;
  const _Header({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_Header] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().coupleDoc(coupleId).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            debugPrint('[_Header] stream error: ${snap.error}');
          }
          Map<String, dynamic>? data;
          try { data = snap.data?.data() as Map<String, dynamic>?; } catch (e) { debugPrint('[_Header] data cast: $e'); }

          DateTime? anniversary;
          try { anniversary = (data?['anniversaryDate'] as Timestamp?)?.toDate(); } catch (e) { debugPrint('[_Header] anniversary cast: $e'); }

          final days = anniversary != null ? DateTime.now().difference(anniversary).inDays : 0;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('HeartSync', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.08)),
                  const SizedBox(height: 4),
                  snap.connectionState == ConnectionState.waiting
                      ? const ShimmerBox(width: 180, height: 28, radius: 6)
                      : Text(
                          anniversary != null ? '$days days together 💕' : 'Welcome home 💕',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: td.primary),
                        ),
                ])),
                const HeartbeatPulse(child: Text('❤️', style: TextStyle(fontSize: 28))),
              ]),
            ),
            HorizonLine(height: 2, colors: [td.primary, td.secondary]),
          ]);
        },
      );
    } catch (e, s) {
      debugPrint('[_Header] BUILD ERROR: $e\n$s');
      return Text('Header error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

// ── Daily Surprise ────────────────────────────────────────────────────────────

class _DailySurprise extends StatefulWidget {
  final String coupleId;
  const _DailySurprise({required this.coupleId});
  @override State<_DailySurprise> createState() => _DailySurpriseState();
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
  String get _todayMsg => _messages[(DateTime.now().month * 31 + DateTime.now().day) % _messages.length];

  @override
  Widget build(BuildContext context) {
    debugPrint('[_DailySurprise] build shouldShow=$_shouldShow');
    try {
      if (!_shouldShow) return const SizedBox.shrink();
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _revealed
              ? Container(
                  key: const ValueKey('r'),
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [td.primary.withValues(alpha: 0.10), td.secondary.withValues(alpha: 0.06)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: td.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Text('✨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_todayMsg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.45))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 15, color: AppTheme.textMuted),
                      onPressed: () { _seenDay[widget.coupleId] = DateTime.now().day; setState(() => _dismissed = true); },
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    ),
                  ]),
                )
              : GestureDetector(
                  key: const ValueKey('g'),
                  onTap: () => setState(() => _revealed = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(color: td.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: td.border)),
                    child: Row(children: [
                      const Text('🎁', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Daily surprise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('Tap to reveal today\'s message', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ])),
                      Icon(Icons.chevron_right, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 16),
                    ]),
                  ),
                ),
        ),
      );
    } catch (e, s) {
      debugPrint('[_DailySurprise] BUILD ERROR: $e\n$s');
      return const SizedBox.shrink();
    }
  }
}

// ── Clock Row ─────────────────────────────────────────────────────────────────

class _ClockRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('[_ClockRow] build');
    try {
      final now = DateTime.now();
      final td = context.watch<ThemeProvider>().data;
      String fmt(DateTime t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _ClockBlock(label: 'Your Time', time: fmt(now), color: td.primary),
            Column(children: [HorizonLine(height: 2), const SizedBox(height: 4), const Text('❤️', style: TextStyle(fontSize: 16))]),
            _ClockBlock(label: "Partner's Time", time: fmt(now.toUtc().add(const Duration(hours: 2))), color: td.primary),
          ]),
        )),
      );
    } catch (e, s) {
      debugPrint('[_ClockRow] BUILD ERROR: $e\n$s');
      return Text('Clock error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

class _ClockBlock extends StatelessWidget {
  final String label, time;
  final Color color;
  const _ClockBlock({required this.label, required this.time, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    const SizedBox(height: 3),
    Text(time, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
  ]);
}

// ── Mood Section ──────────────────────────────────────────────────────────────

class _MoodSection extends StatefulWidget {
  final String coupleId, uid;
  const _MoodSection({required this.coupleId, required this.uid});
  @override State<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends State<_MoodSection> {
  static const _moods = ['😊', '😍', '😔', '🥺', '😤', '🫶'];
  String? _myMood;

  Future<void> _setMood(String mood) async {
    debugPrint('[_MoodSection] setting mood: $mood');
    setState(() => _myMood = mood);
    try {
      await FirestoreService().sub(widget.coupleId, 'moods').add({
        'userId': widget.uid, 'mood': mood, 'timestamp': FieldValue.serverTimestamp()
      });
      await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
    } catch (e) {
      debugPrint('[_MoodSection] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[_MoodSection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Today\'s Mood', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
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
    } catch (e, s) {
      debugPrint('[_MoodSection] BUILD ERROR: $e\n$s');
      return Text('Mood error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

// ── Battery Section ───────────────────────────────────────────────────────────

class _BatterySection extends StatelessWidget {
  final String coupleId;
  const _BatterySection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_BatterySection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().sub(coupleId, 'battery').doc('current').snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            debugPrint('[_BatterySection] error: ${snap.error}');
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Text('🔋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Love Battery', style: TextStyle(fontWeight: FontWeight.w600))),
                  Text('—', style: TextStyle(color: AppTheme.textMuted)),
                ]),
              )),
            );
          }
          int level = 50;
          try {
            final d = snap.data?.data() as Map<String, dynamic>?;
            level = (d?['level'] as num?)?.toInt() ?? 50;
          } catch (e) { debugPrint('[_BatterySection] level cast: $e'); }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Love Battery', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$level%', style: TextStyle(fontWeight: FontWeight.w700, color: td.primary, fontSize: 13)),
                ]),
                const SizedBox(height: 10),
                HorizonLine(progress: level / 100, height: 8, colors: [td.primary, td.secondary]),
              ]),
            )),
          );
        },
      );
    } catch (e, s) {
      debugPrint('[_BatterySection] BUILD ERROR: $e\n$s');
      return Text('Battery error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

// ── Streak Section ────────────────────────────────────────────────────────────

class _StreakSection extends StatelessWidget {
  final String coupleId;
  const _StreakSection({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_StreakSection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().coupleDoc(coupleId).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            debugPrint('[_StreakSection] error: ${snap.error}');
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Streak unavailable', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            );
          }
          int streak = 0;
          try {
            final d = snap.data?.data() as Map<String, dynamic>?;
            streak = (d?['streak'] as num?)?.toInt() ?? 0;
          } catch (e) { debugPrint('[_StreakSection] streak cast: $e'); }
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
                      Expanded(child: Text('Say good night before today ends to protect your streak', style: TextStyle(fontSize: 11, color: AppTheme.warning, height: 1.4))),
                    ]),
                  ),
                ],
              ]),
            )),
          );
        },
      );
    } catch (e, s) {
      debugPrint('[_StreakSection] BUILD ERROR: $e\n$s');
      return Text('Streak error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

// ── Hug Buttons ───────────────────────────────────────────────────────────────

class _HugButtons extends StatelessWidget {
  final String coupleId, uid;
  const _HugButtons({required this.coupleId, required this.uid});

  Future<void> _send(BuildContext ctx, String type) async {
    debugPrint('[_HugButtons] sending type=$type');
    try {
      await FirestoreService().sub(coupleId, 'hugs').add({'fromUid': uid, 'type': type, 'sentAt': FieldValue.serverTimestamp()});
      await FirestoreService().updateDailyAction(coupleId, uid);
      if (ctx.mounted) {
        const msgs = {'hug': 'Hug sent! 🤗', 'kiss': 'Kiss sent! 💋', 'miss': 'Miss you sent! 💭'};
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msgs[type] ?? 'Sent!'), backgroundColor: AppTheme.horizonRose, duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      debugPrint('[_HugButtons] error: $e');
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[_HugButtons] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            const Text('Send', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              HeartButton(size: 64, color: td.primary, label: 'Hug', onPressed: () => _send(context, 'hug'), child: const Text('🤗', style: TextStyle(fontSize: 26))),
              HeartButton(size: 64, color: td.secondary, label: 'Kiss', onPressed: () => _send(context, 'kiss'), child: const Text('💋', style: TextStyle(fontSize: 26))),
              HeartButton(size: 64, color: AppTheme.lavenderDusk, label: 'Miss You', onPressed: () => _send(context, 'miss'), child: const Text('💭', style: TextStyle(fontSize: 26))),
            ]),
          ]),
        )),
      );
    } catch (e, s) {
      debugPrint('[_HugButtons] BUILD ERROR: $e\n$s');
      return Text('HugButtons error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final String coupleId;
  const _QuickActions({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_QuickActions] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          Expanded(child: _ActionCard(icon: Icons.add_photo_alternate_outlined, label: 'Add Memory', color: td.primary,
            onTap: () { try { Navigator.push(context, petalBloomRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))); } catch (e) { debugPrint('[_QuickActions] nav error: $e'); } })),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(icon: Icons.note_add_outlined, label: 'Love Note', color: td.secondary,
            onTap: () { try { Navigator.push(context, petalBloomRoute(builder: (_) => AddNoteScreen(coupleId: coupleId))); } catch (e) { debugPrint('[_QuickActions] nav error: $e'); } })),
        ]),
      );
    } catch (e, s) {
      debugPrint('[_QuickActions] BUILD ERROR: $e\n$s');
      return Text('QuickActions error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override State<_ActionCard> createState() => _ActionCardState();
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
  @override State<_FeatureHub> createState() => _FeatureHubState();
}

class _FeatureHubState extends State<_FeatureHub> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _fades, _scales;
  static const _count = 7;

  @override
  void initState() {
    super.initState();
    debugPrint('[_FeatureHub] initState');
    _ctrls  = List.generate(_count, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 360)));
    _fades  = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _scales = _ctrls.map((c) => Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    for (int i = 0; i < _count; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 65), () { if (mounted) _ctrls[i].forward(); });
    }
  }

  List<_Feature> get _features => [
    _Feature('🌿', 'Garden',      const Color(0xFF4ADE80), (ctx) => GardenScreen(coupleId: widget.coupleId)),
    _Feature('📖', 'Our Story',   AppTheme.lavenderDusk,   (ctx) => MilestonesScreen(coupleId: widget.coupleId)),
    _Feature('🙏', 'Gratitude',   AppTheme.horizonRose,    (ctx) => GratitudeScreen(coupleId: widget.coupleId)),
    _Feature('🌟', 'Dream Board', AppTheme.lavenderDusk,   (ctx) => DreamBoardScreen(coupleId: widget.coupleId)),
    _Feature('💬', 'Connect',     AppTheme.dawnAmber,      (ctx) => ConnectScreen(coupleId: widget.coupleId)),
    _Feature('🏆', 'Challenges',  AppTheme.warning,        (ctx) => ChallengesScreen(coupleId: widget.coupleId)),
    _Feature('✨', 'AI',          const Color(0xFFE05C7E), (ctx) => AiScreen(coupleId: widget.coupleId)),
  ];

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    debugPrint('[_FeatureHub] build');
    try {
      final features = _features;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Text('Everything for you two', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              if (i >= _fades.length || i >= _scales.length) return const SizedBox.shrink();
              return FadeTransition(
                opacity: _fades[i],
                child: ScaleTransition(scale: _scales[i], child: _FeatureCard(feature: features[i])),
              );
            },
          ),
        ),
      ]);
    } catch (e, s) {
      debugPrint('[_FeatureHub] BUILD ERROR: $e\n$s');
      return Text('FeatureHub error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
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
  @override State<_FeatureCard> createState() => _FeatureCardState();
}
class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        try { Navigator.push(context, petalBloomRoute(builder: f.builder)); } catch (e) { debugPrint('[_FeatureCard] nav: $e'); }
      },
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
