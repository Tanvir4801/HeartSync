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

// ── HomeScreen ────────────────────────────────────────────────────────────────

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
                // Phase T: independent hero card — owns its own couple stream
                GreetingHeroCard(coupleId: coupleId),
                const SizedBox(height: 12),
                // Phase T: 4-badge stat row — each badge owns its own data fetch
                StatCardRow(coupleId: coupleId),
                // Daily surprise (independent, unchanged)
                _DailySurprise(coupleId: coupleId),
                // Clock
                _ClockRow(),
                // Mood
                _MoodSection(coupleId: coupleId, uid: uid),
                // Hug buttons
                _HugButtons(coupleId: coupleId, uid: uid),
                // Quick actions
                _QuickActions(coupleId: coupleId),
                // Phase T: renamed from _FeatureHub → FeatureCardCarousel
                FeatureCardCarousel(coupleId: coupleId),
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

// ── Phase T: GreetingHeroCard ─────────────────────────────────────────────────
// Owns its own couple stream. Shows greeting + days together. Fully isolated —
// if this stream fails it shows an error card; nothing else blanks.

class GreetingHeroCard extends StatelessWidget {
  final String coupleId;
  const GreetingHeroCard({super.key, required this.coupleId});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return 'Good morning! 🌅';
    if (h >= 12 && h < 17) return 'Good afternoon! ☀️';
    if (h >= 17 && h < 21) return 'Good evening! 🌙';
    return 'Sweet dreams ahead 🌟';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GreetingHeroCard] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().coupleDoc(coupleId).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) debugPrint('[GreetingHeroCard] stream error: ${snap.error}');

          // Loading state — shimmer shaped like the card
          if (snap.connectionState == ConnectionState.waiting) {
            return _GreetingHeroShimmer(td: td);
          }

          Map<String, dynamic>? data;
          try { data = snap.data?.data() as Map<String, dynamic>?; } catch (e) {
            debugPrint('[GreetingHeroCard] data cast: $e');
          }

          DateTime? anniversary;
          try { anniversary = (data?['anniversaryDate'] as Timestamp?)?.toDate(); } catch (e) {
            debugPrint('[GreetingHeroCard] anniversary cast: $e');
          }

          final days = anniversary != null ? DateTime.now().difference(anniversary).inDays : null;

          return _GreetingHeroCardBody(td: td, days: days, greeting: _greeting());
        },
      );
    } catch (e, s) {
      debugPrint('[GreetingHeroCard] BUILD ERROR: $e\n$s');
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text('Greeting error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11)),
      );
    }
  }
}

class _GreetingHeroCardBody extends StatelessWidget {
  final HeartSyncThemeData td;
  final int? days;
  final String greeting;
  const _GreetingHeroCardBody({required this.td, required this.days, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [td.primary.withValues(alpha: td.isLight ? 0.12 : 0.08), td.secondary.withValues(alpha: td.isLight ? 0.08 : 0.04)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(td.cardRadius),
          border: Border.all(color: td.primary.withValues(alpha: 0.25)),
          boxShadow: td.isLight ? [
            BoxShadow(color: td.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
          ] : [],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              greeting,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: td.textOnSurface.withValues(alpha: td.isLight ? 0.6 : 0.7)),
            ),
            const SizedBox(height: 6),
            days != null
                ? Text(
                    '$days days together 💕',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: td.primary, height: 1.2),
                  )
                : Text(
                    'Welcome home 💕',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: td.primary, height: 1.2),
                  ),
            const SizedBox(height: 4),
            Text(
              'Every day with you counts',
              style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45)),
            ),
          ])),
          const SizedBox(width: 12),
          HeartbeatPulse(
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [td.primary, td.secondary]),
                borderRadius: BorderRadius.circular(td.isLight ? 20 : 16),
                boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('❤️', style: TextStyle(fontSize: 26))),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GreetingHeroShimmer extends StatelessWidget {
  final HeartSyncThemeData td;
  const _GreetingHeroShimmer({required this.td});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: td.shimmerBase,
          borderRadius: BorderRadius.circular(td.cardRadius),
          border: Border.all(color: td.border),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            ShimmerBox(width: 100, height: 12, radius: 6),
            const SizedBox(height: 10),
            ShimmerBox(width: 200, height: 20, radius: 6),
          ])),
          ShimmerBox(width: 56, height: 56, radius: td.isLight ? 20 : 16),
        ]),
      ),
    );
  }
}

// ── Phase T: StatCardRow ──────────────────────────────────────────────────────
// 4 independent badge cards — each owns its own data. One failing stream
// cannot blank the others.

class StatCardRow extends StatelessWidget {
  final String coupleId;
  const StatCardRow({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[StatCardRow] build');
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: _DaysStatBadge(coupleId: coupleId)),
          const SizedBox(width: 10),
          Expanded(child: _StreakStatBadge(coupleId: coupleId)),
          const SizedBox(width: 10),
          Expanded(child: _MemoriesStatBadge(coupleId: coupleId)),
          const SizedBox(width: 10),
          Expanded(child: _BatteryStatBadge(coupleId: coupleId)),
        ]),
      );
    } catch (e, s) {
      debugPrint('[StatCardRow] BUILD ERROR: $e\n$s');
      return const SizedBox.shrink();
    }
  }
}

class _StatBadgeCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color badgeColor;
  final bool loading;
  const _StatBadgeCard({
    required this.emoji, required this.value,
    required this.label, required this.badgeColor, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Container(
      decoration: BoxDecoration(
        color: td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.border),
        boxShadow: td.isLight ? [
          BoxShadow(color: badgeColor.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
        ] : [],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: loading
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ShimmerBox(width: 38, height: 38, radius: 12),
              const SizedBox(height: 6),
              ShimmerBox(width: 30, height: 14, radius: 6),
              const SizedBox(height: 4),
              ShimmerBox(width: 40, height: 10, radius: 5),
            ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: td.textOnSurface, height: 1.1)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, color: td.textOnSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
    );
  }
}

class _DaysStatBadge extends StatelessWidget {
  final String coupleId;
  const _DaysStatBadge({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_DaysStatBadge] build');
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetLavenderPop : AppTheme.lavenderDusk;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _StatBadgeCard(emoji: '🗓️', value: '--', label: 'Days', badgeColor: color, loading: true);
        }
        if (snap.hasError) {
          debugPrint('[_DaysStatBadge] error: ${snap.error}');
          return _StatBadgeCard(emoji: '🗓️', value: '--', label: 'Days', badgeColor: color);
        }
        DateTime? anniversary;
        try {
          final d = snap.data?.data() as Map<String, dynamic>?;
          anniversary = (d?['anniversaryDate'] as Timestamp?)?.toDate();
        } catch (e) { debugPrint('[_DaysStatBadge] cast: $e'); }
        final days = anniversary != null ? DateTime.now().difference(anniversary).inDays : 0;
        return _StatBadgeCard(emoji: '🗓️', value: '$days', label: 'Days', badgeColor: color);
      },
    );
  }
}

class _StreakStatBadge extends StatelessWidget {
  final String coupleId;
  const _StreakStatBadge({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_StreakStatBadge] build');
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetSunshine : AppTheme.warning;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _StatBadgeCard(emoji: '🔥', value: '--', label: 'Streak', badgeColor: color, loading: true);
        }
        if (snap.hasError) {
          debugPrint('[_StreakStatBadge] error: ${snap.error}');
          return _StatBadgeCard(emoji: '🔥', value: '--', label: 'Streak', badgeColor: color);
        }
        int streak = 0;
        try {
          final d = snap.data?.data() as Map<String, dynamic>?;
          streak = (d?['streak'] as num?)?.toInt() ?? 0;
        } catch (e) { debugPrint('[_StreakStatBadge] cast: $e'); }
        return _StatBadgeCard(emoji: '🔥', value: '$streak', label: 'Streak', badgeColor: color);
      },
    );
  }
}

class _MemoriesStatBadge extends StatelessWidget {
  final String coupleId;
  const _MemoriesStatBadge({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_MemoriesStatBadge] build');
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetCoralBlush : AppTheme.horizonRose;
    return FutureBuilder<QuerySnapshot>(
      future: FirestoreService().sub(coupleId, 'memories').get(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _StatBadgeCard(emoji: '📸', value: '--', label: 'Memories', badgeColor: color, loading: true);
        }
        if (snap.hasError) {
          debugPrint('[_MemoriesStatBadge] error: ${snap.error}');
          return _StatBadgeCard(emoji: '📸', value: '--', label: 'Memories', badgeColor: color);
        }
        final count = snap.data?.docs.length ?? 0;
        return _StatBadgeCard(emoji: '📸', value: '$count', label: 'Memories', badgeColor: color);
      },
    );
  }
}

class _BatteryStatBadge extends StatelessWidget {
  final String coupleId;
  const _BatteryStatBadge({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_BatteryStatBadge] build');
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetSkyMint : AppTheme.success;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().sub(coupleId, 'battery').doc('current').snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _StatBadgeCard(emoji: '🔋', value: '--', label: 'Battery', badgeColor: color, loading: true);
        }
        if (snap.hasError) {
          debugPrint('[_BatteryStatBadge] error: ${snap.error}');
          return _StatBadgeCard(emoji: '🔋', value: '--', label: 'Battery', badgeColor: color);
        }
        int level = 50;
        try {
          final d = snap.data?.data() as Map<String, dynamic>?;
          level = (d?['level'] as num?)?.toInt() ?? 50;
        } catch (e) { debugPrint('[_BatteryStatBadge] cast: $e'); }
        return _StatBadgeCard(emoji: '🔋', value: '$level%', label: 'Battery', badgeColor: color);
      },
    );
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
                    borderRadius: BorderRadius.circular(td.cardRadius),
                    border: Border.all(color: td.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Text('✨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_todayMsg, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.45, color: td.textOnSurface))),
                    IconButton(
                      icon: Icon(Icons.close, size: 15, color: td.textOnSurface.withValues(alpha: 0.4)),
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
                    decoration: BoxDecoration(color: td.surface, borderRadius: BorderRadius.circular(td.cardRadius), border: Border.all(color: td.border)),
                    child: Row(children: [
                      const Text('🎁', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Daily surprise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: td.textOnSurface)),
                        Text('Tap to reveal today\'s message', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45))),
                      ])),
                      Icon(Icons.chevron_right, color: td.textOnSurface.withValues(alpha: 0.3), size: 16),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.border),
            boxShadow: td.isLight ? [BoxShadow(color: td.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _ClockBlock(label: 'Your Time', time: fmt(now), color: td.primary, textColor: td.textOnSurface),
            Column(children: [HorizonLine(height: 2, colors: [td.primary, td.secondary]), const SizedBox(height: 4), const Text('❤️', style: TextStyle(fontSize: 16))]),
            _ClockBlock(label: "Partner's Time", time: fmt(now.toUtc().add(const Duration(hours: 2))), color: td.primary, textColor: td.textOnSurface),
          ]),
        ),
      );
    } catch (e, s) {
      debugPrint('[_ClockRow] BUILD ERROR: $e\n$s');
      return Text('Clock error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
    }
  }
}

class _ClockBlock extends StatelessWidget {
  final String label, time;
  final Color color, textColor;
  const _ClockBlock({required this.label, required this.time, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.45))),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.border),
            boxShadow: td.isLight ? [BoxShadow(color: td.secondary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Mood', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
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
        ),
      );
    } catch (e, s) {
      debugPrint('[_MoodSection] BUILD ERROR: $e\n$s');
      return Text('Mood error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.border),
            boxShadow: td.isLight ? [BoxShadow(color: td.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text('Send', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              HeartButton(size: 64, color: td.primary, label: 'Hug', onPressed: () => _send(context, 'hug'), child: const Text('🤗', style: TextStyle(fontSize: 26))),
              HeartButton(size: 64, color: td.secondary, label: 'Kiss', onPressed: () => _send(context, 'kiss'), child: const Text('💋', style: TextStyle(fontSize: 26))),
              HeartButton(size: 64, color: td.accent, label: 'Miss You', onPressed: () => _send(context, 'miss'), child: const Text('💭', style: TextStyle(fontSize: 26))),
            ]),
          ]),
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(scale: _pressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 100),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: td.isLight ? 0.10 : 0.08),
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
            boxShadow: td.isLight ? [BoxShadow(color: widget.color.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(children: [
            Icon(widget.icon, color: widget.color, size: 26),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.color)),
          ]),
        ),
      ),
    );
  }
}

// ── Phase T: FeatureCardCarousel (was _FeatureHub) ────────────────────────────
// Independent widget — if one card fails to tap it logs but doesn't crash others.

class FeatureCardCarousel extends StatefulWidget {
  final String coupleId;
  const FeatureCardCarousel({super.key, required this.coupleId});
  @override State<FeatureCardCarousel> createState() => _FeatureCardCarouselState();
}

class _FeatureCardCarouselState extends State<FeatureCardCarousel> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _fades, _scales;
  static const _count = 7;

  @override
  void initState() {
    super.initState();
    debugPrint('[FeatureCardCarousel] initState');
    _ctrls  = List.generate(_count, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 360)));
    _fades  = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _scales = _ctrls.map((c) => Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    for (int i = 0; i < _count; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 65), () { if (mounted) _ctrls[i].forward(); });
    }
  }

  List<_Feature> _features(HeartSyncThemeData td) => [
    _Feature('🌿', 'Garden',      td.badgeColors[0], (ctx) => GardenScreen(coupleId: widget.coupleId)),
    _Feature('📖', 'Our Story',   td.badgeColors[1], (ctx) => MilestonesScreen(coupleId: widget.coupleId)),
    _Feature('🙏', 'Gratitude',   td.badgeColors[2], (ctx) => GratitudeScreen(coupleId: widget.coupleId)),
    _Feature('🌟', 'Dream Board', td.badgeColors[3], (ctx) => DreamBoardScreen(coupleId: widget.coupleId)),
    _Feature('💬', 'Connect',     td.badgeColors[4], (ctx) => ConnectScreen(coupleId: widget.coupleId)),
    _Feature('🏆', 'Challenges',  td.badgeColors[5], (ctx) => ChallengesScreen(coupleId: widget.coupleId)),
    _Feature('✨', 'AI',          td.badgeColors[6], (ctx) => AiScreen(coupleId: widget.coupleId)),
  ];

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    debugPrint('[FeatureCardCarousel] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      final features = _features(td);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text('Everything for you two', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: td.textOnSurface)),
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
                child: ScaleTransition(scale: _scales[i], child: _FeatureCard(feature: features[i], td: td)),
              );
            },
          ),
        ),
      ]);
    } catch (e, s) {
      debugPrint('[FeatureCardCarousel] BUILD ERROR: $e\n$s');
      return Text('FeatureCarousel error: $e', style: const TextStyle(color: AppTheme.danger, fontSize: 11));
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
  final HeartSyncThemeData td;
  const _FeatureCard({required this.feature, required this.td});
  @override State<_FeatureCard> createState() => _FeatureCardState();
}
class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    final td = widget.td;
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
            color: td.isLight ? td.surface : f.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.isLight ? td.border : f.color.withValues(alpha: 0.28)),
            boxShadow: td.isLight ? [BoxShadow(color: f.color.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 5))] : [],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: f.color, borderRadius: BorderRadius.circular(td.isLight ? 18 : 14)),
              child: Center(child: Text(f.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 8),
            Text(f.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: td.isLight ? td.textOnSurface : f.color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
