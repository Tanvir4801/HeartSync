import 'dart:async';
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
import '../../sync/screens/sync_zone_screen.dart';

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
      return ColoredBox(
        color: td.background,
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const _HomeIntroCard(),
              const SizedBox(height: 8),
              // Invisible presence writer — writes to Firestore every 3 min
              _PresenceWriter(coupleId: coupleId, uid: uid),
              // Hero card with partner online indicator
              GreetingHeroCard(coupleId: coupleId, uid: uid),
              const SizedBox(height: 12),
              // 4 independent stat badges
              StatCardRow(coupleId: coupleId),
              // ❤️ NEW: Virtual Heartbeat Tap
              _HeartbeatSection(coupleId: coupleId, uid: uid),
              // Daily surprise
              _DailySurprise(coupleId: coupleId),
              // Clock row
              _ClockRow(),
              // Mood picker
              _MoodSection(coupleId: coupleId, uid: uid),
              // ❤️ NEW: Duo Vibe Reveal (shows combined couple energy after both pick)
              _DuoVibeSection(coupleId: coupleId, uid: uid),
              // ❤️ NEW: Secret Love Jar
              _LoveJarSection(coupleId: coupleId, uid: uid),
              // Hug buttons
              _HugButtons(coupleId: coupleId, uid: uid),
              // Quick actions
              _QuickActions(coupleId: coupleId),
              // Feature carousel
              FeatureCardCarousel(coupleId: coupleId),
            ],
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

class _HomeIntroCard extends StatelessWidget {
  const _HomeIntroCard();

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              td.primary.withValues(alpha: td.isLight ? 0.24 : 0.22),
              td.secondary.withValues(alpha: td.isLight ? 0.20 : 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(td.cardRadius),
          border: Border.all(color: td.primary.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: td.primary.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: td.isLight ? 0.92 : 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.favorite, color: td.isLight ? td.primary : Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Ready',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: td.isLight ? td.textOnSurface : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If anything below is still loading, this banner confirms the page is mounted and ready.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: td.isLight ? td.textOnSurface.withValues(alpha: 0.74) : Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Invisible Presence Writer ─────────────────────────────────────────────────
// Writes current user's online status into the couple doc every 3 minutes.
// No visible UI — returns an empty widget.

class _PresenceWriter extends StatefulWidget {
  final String coupleId, uid;
  const _PresenceWriter({required this.coupleId, required this.uid});
  @override State<_PresenceWriter> createState() => _PresenceWriterState();
}

class _PresenceWriterState extends State<_PresenceWriter> {
  Timer? _timer;

  Future<void> _ping() async {
    if (widget.uid.isEmpty) return;
    try {
      await FirestoreService().coupleDoc(widget.coupleId).set({
        'presence': {
          widget.uid: { 'lastSeen': FieldValue.serverTimestamp() },
        },
      }, SetOptions(merge: true));
    } catch (e) { debugPrint('[_PresenceWriter] ping error: $e'); }
  }

  @override
  void initState() {
    super.initState();
    _ping();
    _timer = Timer.periodic(const Duration(minutes: 3), (_) => _ping());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── GreetingHeroCard (with partner online indicator) ──────────────────────────

class GreetingHeroCard extends StatelessWidget {
  final String coupleId, uid;
  const GreetingHeroCard({super.key, required this.coupleId, required this.uid});

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

          // Partner online indicator
          final members = List<String>.from(data?['members'] ?? []);
          final partnerUid = members.firstWhere((m) => m != uid, orElse: () => '');
          bool? partnerOnline;
          if (partnerUid.isNotEmpty) {
            try {
              final presenceMap = data?['presence'] as Map<String, dynamic>?;
              final partnerPresence = presenceMap?[partnerUid] as Map<String, dynamic>?;
              final lastSeen = (partnerPresence?['lastSeen'] as Timestamp?)?.toDate();
              if (lastSeen != null) {
                final diff = DateTime.now().difference(lastSeen);
                partnerOnline = diff.inMinutes < 5;
              }
            } catch (e) { debugPrint('[GreetingHeroCard] presence: $e'); }
          }

          return _GreetingHeroCardBody(
            td: td, days: days, greeting: _greeting(), partnerOnline: partnerOnline,
          );
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
  final bool? partnerOnline; // null = unknown, true = online, false = offline
  const _GreetingHeroCardBody({required this.td, required this.days, required this.greeting, required this.partnerOnline});

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
                ? Text('$days days together 💕', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: td.primary, height: 1.2))
                : Text('Welcome home 💕', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: td.primary, height: 1.2)),
            const SizedBox(height: 8),
            // Partner online indicator
            if (partnerOnline != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                _OnlineDot(online: partnerOnline!, color: partnerOnline! ? AppTheme.success : AppTheme.textMuted),
                const SizedBox(width: 5),
                Text(
                  partnerOnline! ? 'Your love is here 💚' : 'Partner offline',
                  style: TextStyle(fontSize: 11, color: partnerOnline! ? AppTheme.success : td.textOnSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
                ),
              ])
            else
              Text('Every day with you counts', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45))),
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

class _OnlineDot extends StatefulWidget {
  final bool online;
  final Color color;
  const _OnlineDot({required this.online, required this.color});
  @override State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.online) _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: widget.online ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 6 * _scale.value, spreadRadius: 1 * _scale.value)] : [],
      ),
    ),
  );
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
        decoration: BoxDecoration(color: td.shimmerBase, borderRadius: BorderRadius.circular(td.cardRadius), border: Border.all(color: td.border)),
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

// ── StatCardRow ───────────────────────────────────────────────────────────────

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
  final String emoji, value, label;
  final Color badgeColor;
  final bool loading;
  const _StatBadgeCard({required this.emoji, required this.value, required this.label, required this.badgeColor, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    return Container(
      decoration: BoxDecoration(
        color: td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.border),
        boxShadow: td.isLight ? [BoxShadow(color: badgeColor.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))] : [],
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
              Container(width: 38, height: 38, decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
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
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetLavenderPop : AppTheme.lavenderDusk;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _StatBadgeCard(emoji: '🗓️', value: '--', label: 'Days', badgeColor: color, loading: true);
        if (snap.hasError) return _StatBadgeCard(emoji: '🗓️', value: '--', label: 'Days', badgeColor: color);
        DateTime? ann;
        try { final d = snap.data?.data() as Map<String, dynamic>?; ann = (d?['anniversaryDate'] as Timestamp?)?.toDate(); } catch (_) {}
        final days = ann != null ? DateTime.now().difference(ann).inDays : 0;
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
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetSunshine : AppTheme.warning;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().coupleDoc(coupleId).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _StatBadgeCard(emoji: '🔥', value: '--', label: 'Streak', badgeColor: color, loading: true);
        if (snap.hasError) return _StatBadgeCard(emoji: '🔥', value: '--', label: 'Streak', badgeColor: color);
        int streak = 0;
        try { final d = snap.data?.data() as Map<String, dynamic>?; streak = (d?['streak'] as num?)?.toInt() ?? 0; } catch (_) {}
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
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetCoralBlush : AppTheme.horizonRose;
    return FutureBuilder<QuerySnapshot>(
      future: FirestoreService().sub(coupleId, 'memories').get(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _StatBadgeCard(emoji: '📸', value: '--', label: 'Memories', badgeColor: color, loading: true);
        if (snap.hasError) return _StatBadgeCard(emoji: '📸', value: '--', label: 'Memories', badgeColor: color);
        return _StatBadgeCard(emoji: '📸', value: '${snap.data?.docs.length ?? 0}', label: 'Memories', badgeColor: color);
      },
    );
  }
}

class _BatteryStatBadge extends StatelessWidget {
  final String coupleId;
  const _BatteryStatBadge({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final color = td.isLight ? AppTheme.sweetSkyMint : AppTheme.success;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().sub(coupleId, 'battery').doc('current').snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _StatBadgeCard(emoji: '🔋', value: '--', label: 'Battery', badgeColor: color, loading: true);
        if (snap.hasError) return _StatBadgeCard(emoji: '🔋', value: '--', label: 'Battery', badgeColor: color);
        int level = 50;
        try { final d = snap.data?.data() as Map<String, dynamic>?; level = (d?['level'] as num?)?.toInt() ?? 50; } catch (_) {}
        return _StatBadgeCard(emoji: '🔋', value: '$level%', label: 'Battery', badgeColor: color);
      },
    );
  }
}

// ── ❤️ NEW: Virtual Heartbeat Tap ────────────────────────────────────────────
// Tap the heart to send your heartbeat to your partner.
// If partner sent a heartbeat in the last 90 seconds, show an incoming pulse.

class _HeartbeatSection extends StatefulWidget {
  final String coupleId, uid;
  const _HeartbeatSection({required this.coupleId, required this.uid});
  @override State<_HeartbeatSection> createState() => _HeartbeatSectionState();
}

class _HeartbeatSectionState extends State<_HeartbeatSection> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _rippleRadius;
  late Animation<double> _rippleOpa;
  bool _sending = false;
  bool _receivedRecently = false;
  String? _partnerName;
  StreamSubscription? _sub;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rippleRadius = Tween(begin: 0.5, end: 1.5).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _rippleOpa = Tween(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _listenHeartbeats();
  }

  void _listenHeartbeats() {
    final since = DateTime.now().subtract(const Duration(seconds: 90));
    _sub = FirestoreService().sub(widget.coupleId, 'heartbeats')
        .orderBy('sentAt', descending: true).limit(3)
        .snapshots().listen((snap) {
      if (!mounted) return;
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>?;
        final fromUid = d?['fromUid'] as String?;
        final sentAt = (d?['sentAt'] as Timestamp?)?.toDate();
        if (fromUid != null && fromUid != widget.uid && sentAt != null && sentAt.isAfter(since)) {
          if (!_receivedRecently) {
            setState(() { _receivedRecently = true; _partnerName = d?['partnerName'] as String? ?? 'Your love'; });
            _rippleCtrl.forward(from: 0).then((_) => _rippleCtrl.repeat());
            _clearTimer?.cancel();
            _clearTimer = Timer(const Duration(seconds: 8), () {
              if (mounted) {
                setState(() => _receivedRecently = false);
                _rippleCtrl.stop();
              }
            });
          }
          break;
        }
      }
    }, onError: (e) => debugPrint('[_HeartbeatSection] stream error: $e'));
  }

  Future<void> _sendHeartbeat() async {
    if (_sending) return;
    setState(() => _sending = true);
    _pulseCtrl.forward(from: 0);
    try {
      await FirestoreService().sub(widget.coupleId, 'heartbeats').add({
        'fromUid': widget.uid,
        'sentAt': FieldValue.serverTimestamp(),
        'type': 'heartbeat',
      });
      await FirestoreService().updateDailyAction(widget.coupleId, widget.uid);
    } catch (e) { debugPrint('[_HeartbeatSection] send error: $e'); }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _rippleCtrl.dispose(); _sub?.cancel(); _clearTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    debugPrint('[_HeartbeatSection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.isLight ? td.secondary.withValues(alpha: 0.3) : td.border),
            boxShadow: td.isLight ? [BoxShadow(color: td.secondary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))] : [],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            // Big heart tap button with ripple
            GestureDetector(
              onTap: _sendHeartbeat,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtrl, _rippleCtrl]),
                builder: (_, __) => SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
                  // Ripple ring (shows when received)
                  if (_receivedRecently)
                    Container(
                      width: 80 * _rippleRadius.value,
                      height: 80 * _rippleRadius.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: td.secondary.withValues(alpha: _rippleOpa.value), width: 2),
                      ),
                    ),
                  // Heart
                  ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [td.secondary.withValues(alpha: 0.25), td.secondary.withValues(alpha: 0.08)]),
                        border: Border.all(color: td.secondary.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Center(child: Text(_receivedRecently ? '💓' : '🫀', style: const TextStyle(fontSize: 30))),
                    ),
                  ),
                ])),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Virtual Heartbeat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: td.textOnSurface)),
              const SizedBox(height: 4),
              if (_receivedRecently)
                Text('💓 ${_partnerName ?? "Your love"} just sent you their heartbeat!', style: TextStyle(fontSize: 12, color: td.secondary, fontWeight: FontWeight.w600, height: 1.4))
              else
                Text('Tap to send your heartbeat to your partner. They\'ll feel it instantly 💕', style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.5), height: 1.4)),
              const SizedBox(height: 10),
              _sending
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: td.secondary))
                  : GestureDetector(
                      onTap: _sendHeartbeat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: td.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: td.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Text('Send Heartbeat 💗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: td.secondary)),
                      ),
                    ),
            ])),
          ]),
        ),
      );
    } catch (e, s) {
      debugPrint('[_HeartbeatSection] BUILD ERROR: $e\n$s');
      return const SizedBox.shrink();
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
    debugPrint('[_DailySurprise] build');
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
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HorizonLine(height: 2, colors: [td.primary, td.secondary]),
                  const SizedBox(height: 4),
                  const Text('❤️', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
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
    } catch (e) { debugPrint('[_MoodSection] error: $e'); }
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

// ── ❤️ NEW: Duo Vibe Reveal ────────────────────────────────────────────────────
// After both partners set their mood today, combine them into a "couple vibe".
// If only one picked, gently nudge the other to pick too.

class _DuoVibeSection extends StatelessWidget {
  final String coupleId, uid;
  const _DuoVibeSection({required this.coupleId, required this.uid});

  static const _vibeMap = {
    '😊😊': ('Sunshine Day ☀️', '0xFFF3C98B'),
    '😊😍': ('Romance Blooming 🌹', '0xFFE05C7E'),
    '😍😍': ('Head Over Heels 💘', '0xFFE8A598'),
    '😍🫶': ('Pure Love Energy 💜', '0xFF9B87F5'),
    '😊🫶': ('Warm & Cozy 🌻', '0xFFF2A65A'),
    '🥺😍': ('Tender Hearts 💝', '0xFFFF9EB5'),
    '🥺🫶': ('Holding Each Other 🤗', '0xFFFFD66B'),
    '😔🥺': ('We Feel Everything Together 🌧️', '0xFFA78BFA'),
    '😤😊': ('Opposites Balance ⚖️', '0xFF56CFE1'),
    '🫶🫶': ('Unconditional Love ∞', '0xFF9B87F5'),
    '😍😊': ('Romance Blooming 🌹', '0xFFE05C7E'),
    '🫶😍': ('Pure Love Energy 💜', '0xFF9B87F5'),
    '🫶😊': ('Warm & Cozy 🌻', '0xFFF2A65A'),
    '😍🥺': ('Tender Hearts 💝', '0xFFFF9EB5'),
    '🫶🥺': ('Holding Each Other 🤗', '0xFFFFD66B'),
    '🥺😔': ('We Feel Everything Together 🌧️', '0xFFA78BFA'),
    '😊😤': ('Opposites Balance ⚖️', '0xFF56CFE1'),
  };

  @override
  Widget build(BuildContext context) {
    debugPrint('[_DuoVibeSection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      return StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().sub(coupleId, 'moods')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .orderBy('timestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (_, snap) {
          if (snap.hasError) { debugPrint('[_DuoVibeSection] error: ${snap.error}'); return const SizedBox.shrink(); }
          if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
          final docs = snap.data?.docs ?? [];
          final latestByUser = <String, String>{};
          for (final doc in docs) {
            final d = doc.data() as Map<String, dynamic>?;
            final userId = d?['userId'] as String?;
            final mood = d?['mood'] as String?;
            if (userId != null && mood != null && !latestByUser.containsKey(userId)) {
              latestByUser[userId] = mood;
            }
          }
          final myMood = latestByUser[uid];
          final partnerMood = latestByUser.entries.firstWhere((e) => e.key != uid, orElse: () => const MapEntry('', '')).value;
          final partnerMoodVal = partnerMood.isEmpty ? null : partnerMood;
          if (myMood == null && partnerMoodVal == null) return const SizedBox.shrink();
          if (myMood != null && partnerMoodVal == null) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: td.surface, borderRadius: BorderRadius.circular(td.cardRadius),
                  border: Border.all(color: td.primary.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Text(myMood, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text('+ ❓', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('You set your mood! Waiting for partner to vibe with you...', style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55), height: 1.4))),
                ]),
              ),
            );
          }
          // Both picked!
          final key1 = '$myMood$partnerMoodVal';
          final key2 = '$partnerMoodVal$myMood';
          final vibe = _vibeMap[key1] ?? _vibeMap[key2] ?? ('Unique Duo Energy ✨', '0xFFE05C7E');
          final vibeColor = Color(int.parse(vibe.$2));
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [vibeColor.withValues(alpha: 0.10), vibeColor.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(td.cardRadius),
                border: Border.all(color: vibeColor.withValues(alpha: 0.35)),
                boxShadow: td.isLight ? [BoxShadow(color: vibeColor.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 5))] : [],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Today\'s Couple Vibe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: td.textOnSurface.withValues(alpha: 0.5))),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: vibeColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                    child: Text('COMBINED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: vibeColor))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Text(myMood ?? '?', style: const TextStyle(fontSize: 32)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.add, color: vibeColor, size: 18),
                  ),
                  Text(partnerMoodVal ?? '?', style: const TextStyle(fontSize: 32)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: vibeColor, size: 16),
                  ),
                  Expanded(child: Text(vibe.$1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: vibeColor, height: 1.3))),
                ]),
              ]),
            ),
          );
        },
      );
    } catch (e, s) {
      debugPrint('[_DuoVibeSection] BUILD ERROR: $e\n$s');
      return const SizedBox.shrink();
    }
  }
}

// ── ❤️ NEW: Secret Love Jar ───────────────────────────────────────────────────
// A virtual jar of sweet messages — tap to shake & reveal one.
// Partners can drop custom notes into each other's jar.

class _LoveJarSection extends StatefulWidget {
  final String coupleId, uid;
  const _LoveJarSection({required this.coupleId, required this.uid});
  @override State<_LoveJarSection> createState() => _LoveJarSectionState();
}

class _LoveJarSectionState extends State<_LoveJarSection> with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  bool _revealed = false;
  int _revealIndex = 0;
  List<String> _customMessages = [];
  bool _loadingJar = true;

  static const _sweetMessages = [
    'You make ordinary moments extraordinary 💫',
    'I fall more in love with you every single day 💕',
    'You are my favorite notification 📱💗',
    'The world is better because you\'re in it 🌍✨',
    'You make my heart do the happy dance 💃',
    'Missing you is my heart\'s favorite hobby 💭',
    'You\'re the best thing that happened to my story 📖',
    'I choose you. Every single day. 💍',
    'You\'re my home, no matter where we are 🏡',
    'Loving you is the easiest thing I\'ve ever done 💝',
    'You make distance feel like nothing 🌸',
    'My love for you grows with every sunrise 🌅',
    'You are someone worth waiting for 💌',
    'Counting down the moments until I see you again ⏰',
    'You make every day a little more magical ✨',
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _revealIndex = (DateTime.now().day + DateTime.now().month) % _sweetMessages.length;
    _loadJar();
  }

  Future<void> _loadJar() async {
    try {
      final snap = await FirestoreService()
          .sub(widget.coupleId, 'lovejar')
          .where('toUid', isEqualTo: widget.uid)
          .limit(20)
          .get();
      if (mounted) {
        setState(() {
          _customMessages = snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>?;
            return data?['message'] as String? ?? '';
          }).where((m) => m.isNotEmpty).toList();
          _loadingJar = false;
        });
      }
    } catch (e) {
      debugPrint('[_LoveJarSection] load error: $e');
      if (mounted) setState(() => _loadingJar = false);
    }
  }

  Future<void> _addNote(BuildContext ctx) async {
    final td = context.read<ThemeProvider>().data;
    String? message;
    await showDialog(
      context: ctx,
      builder: (_) => _AddJarNoteDialog(td: td, onSave: (m) => message = m),
    );
    if (message != null && message!.trim().isNotEmpty) {
      try {
        // Get partner UID from couple doc
        final doc = await FirestoreService().coupleDoc(widget.coupleId).get();
        final members = List<String>.from((doc.data() as Map<String, dynamic>?)?['members'] ?? []);
        final partnerUid = members.firstWhere((m) => m != widget.uid, orElse: () => '');
        if (partnerUid.isNotEmpty) {
          await FirestoreService().sub(widget.coupleId, 'lovejar').add({
            'message': message!.trim(),
            'fromUid': widget.uid,
            'toUid': partnerUid,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('💌 Note dropped in their Love Jar!'),
            backgroundColor: Color(0xFFE05C7E),
            duration: Duration(seconds: 2),
          ));
        }
      } catch (e) { debugPrint('[_LoveJarSection] add error: $e'); }
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() { _revealed = true; _revealIndex = math.Random().nextInt(_sweetMessages.length); });
    });
  }

  String get _currentMessage {
    if (_customMessages.isNotEmpty) {
      return _customMessages[_revealIndex % _customMessages.length];
    }
    return _sweetMessages[_revealIndex % _sweetMessages.length];
  }

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    debugPrint('[_LoveJarSection] build');
    try {
      final td = context.watch<ThemeProvider>().data;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(color: td.isLight ? td.primary.withValues(alpha: 0.25) : td.border),
            boxShadow: td.isLight ? [BoxShadow(color: td.primary.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 6))] : [],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
                child: GestureDetector(
                  onTap: _shake,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [td.primary.withValues(alpha: 0.15), td.accent.withValues(alpha: 0.10)]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: td.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Center(child: Text('🫙', style: TextStyle(fontSize: 28))),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Secret Love Jar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: td.textOnSurface)),
                  if (_customMessages.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: td.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text('${_customMessages.length}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(
                  _loadingJar ? 'Loading your jar...' : 'Shake for a sweet surprise 🍬',
                  style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45)),
                ),
              ])),
              // Add to partner's jar
              GestureDetector(
                onTap: () => _addNote(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: td.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: td.accent.withValues(alpha: 0.4))),
                  child: Text('+ Drop Note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: td.isLight ? AppTheme.sweetPlumInk : td.accent)),
                ),
              ),
            ]),
            if (_revealed) ...[
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey(_revealIndex),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [td.primary.withValues(alpha: 0.08), td.secondary.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(td.cardRadius - 4),
                    border: Border.all(color: td.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Text(_customMessages.isNotEmpty ? '💌' : '🍬', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_currentMessage, style: TextStyle(fontSize: 13, color: td.textOnSurface, height: 1.5, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => setState(() { _shake(); }),
                      child: Icon(Icons.refresh_rounded, size: 16, color: td.primary.withValues(alpha: 0.5)),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      );
    } catch (e, s) {
      debugPrint('[_LoveJarSection] BUILD ERROR: $e\n$s');
      return const SizedBox.shrink();
    }
  }
}

class _AddJarNoteDialog extends StatefulWidget {
  final HeartSyncThemeData td;
  final ValueChanged<String> onSave;
  const _AddJarNoteDialog({required this.td, required this.onSave});
  @override State<_AddJarNoteDialog> createState() => _AddJarNoteDialogState();
}

class _AddJarNoteDialogState extends State<_AddJarNoteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final td = widget.td;
    return AlertDialog(
      backgroundColor: td.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(td.cardRadius)),
      title: Text('Drop a Love Note 🫙', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: td.textOnSurface)),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        maxLength: 150,
        style: TextStyle(color: td.textOnSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Write something sweet for your partner...',
          filled: true, fillColor: td.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: td.primary, width: 1.5)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: td.textOnSurface.withValues(alpha: 0.4))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: td.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), minimumSize: const Size(0, 38)),
          onPressed: () { widget.onSave(_ctrl.text); Navigator.pop(context); },
          child: const Text('Drop it in! 💕'),
        ),
      ],
    );
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

// ── FeatureCardCarousel ───────────────────────────────────────────────────────

class FeatureCardCarousel extends StatefulWidget {
  final String coupleId;
  const FeatureCardCarousel({super.key, required this.coupleId});
  @override State<FeatureCardCarousel> createState() => _FeatureCardCarouselState();
}

class _FeatureCardCarouselState extends State<FeatureCardCarousel> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _fades, _scales;
  static const _count = 8;

  @override
  void initState() {
    super.initState();
    debugPrint('[FeatureCardCarousel] initState');
    _ctrls  = List.generate(_count, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 360)));
    _fades  = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _scales = _ctrls.map((c) => Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    for (int i = 0; i < _count; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 65), () {
        if (mounted) {
          _ctrls[i].forward();
        }
      });
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
    _Feature('⚡', 'Sync Zone',   td.accent,          (ctx) => SyncZoneScreen(coupleId: widget.coupleId)),
  ];

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

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
