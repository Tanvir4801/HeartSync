import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/firestore_service.dart';
import '../../../core/widgets/petal_bloom_route.dart';
import '../sync_session_controller.dart';
import 'radio_room_screen.dart';
import 'watch_together_screen.dart';
import 'spotify_together_screen.dart';

// ─── Sync Zone Screen ─────────────────────────────────────────────────────────
// Phase Z-4 — Hub for all three sync features

class SyncZoneScreen extends StatefulWidget {
  final String coupleId;
  const SyncZoneScreen({super.key, required this.coupleId});
  @override State<SyncZoneScreen> createState() => _SyncZoneScreenState();
}

class _SyncZoneScreenState extends State<SyncZoneScreen> with TickerProviderStateMixin {
  // _uid used for future conductor/listener identification
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late AnimationController _connectionCtrl;
  late AnimationController _pulseCtrl;

  String _myInitial = 'Y';
  String _partnerInitial = '♡';
  SyncSession? _activeSession;
  StreamSubscription? _sessionSub;

  @override
  void initState() {
    super.initState();
    _connectionCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _loadPartner();
    _listenSession();
  }

  Future<void> _loadPartner() async {
    try {
      final doc = await FirestoreService().coupleDoc(widget.coupleId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final emails = List<String>.from(data?['memberEmails'] ?? []);
      final myEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      final pEmail = emails.firstWhere((e) => e != myEmail, orElse: () => '');
      final myName = myEmail.split('@')[0].split(RegExp(r'[._]')).first;
      final pName = pEmail.split('@')[0].split(RegExp(r'[._]')).first;
      if (mounted) setState(() {
        _myInitial = myName.isNotEmpty ? myName[0].toUpperCase() : 'Y';
        _partnerInitial = pName.isNotEmpty ? pName[0].toUpperCase() : '♡';
      });
    } catch (e) { debugPrint('[SyncZone] loadPartner: $e'); }
  }

  void _listenSession() {
    _sessionSub = FirebaseFirestore.instance
        .collection('couples')
        .doc(widget.coupleId)
        .collection('syncSession')
        .doc('active')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          if (!snap.exists) { setState(() => _activeSession = null); return; }
          final data = snap.data() as Map<String, dynamic>?;
          if (data == null) return;
          final s = SyncSession.fromMap(data);
          setState(() => _activeSession = s.isActive ? s : null);
        });
  }

  @override
  void dispose() {
    _connectionCtrl.dispose();
    _pulseCtrl.dispose();
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        backgroundColor: td.background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sync Zone ⚡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: td.textOnSurface)),
          Text('Experience things together', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45))),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Hero: two avatars + pulsing connection ─────────────────────
          _HeroSection(
            myInitial: _myInitial,
            partnerInitial: _partnerInitial,
            connectionCtrl: _connectionCtrl,
            pulseCtrl: _pulseCtrl,
            td: td,
            activeSession: _activeSession,
          ),
          const SizedBox(height: 24),

          // ── Active session banner ──────────────────────────────────────
          if (_activeSession != null)
            _ActiveSessionBanner(
              session: _activeSession!,
              td: td,
              coupleId: widget.coupleId,
              onRejoin: () => _rejoinSession(context, _activeSession!),
            ),
          if (_activeSession != null) const SizedBox(height: 16),

          // ── Feature cards ──────────────────────────────────────────────
          _SyncCard(
            emoji: '📻',
            title: 'Couple Radio',
            subtitle: 'Your private shared station — songs you love, streamed to both of you in sync.',
            badge: 'No account needed',
            badgeColor: const Color(0xFF4ADE80),
            td: td,
            isActive: _activeSession?.type == SyncType.radio,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => RadioRoomScreen(coupleId: widget.coupleId))),
          ),
          const SizedBox(height: 12),
          _SyncCard(
            emoji: '🎧',
            title: 'Spotify Together',
            subtitle: 'Listen to any Spotify track in perfect sync across any distance.',
            badge: 'Spotify accounts required',
            badgeColor: const Color(0xFF1DB954),
            td: td,
            isActive: _activeSession?.type == SyncType.music,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => const SpotifyTogetherScreen())),
          ),
          const SizedBox(height: 12),
          _SyncCard(
            emoji: '🎬',
            title: 'Watch Together',
            subtitle: 'Watch any YouTube video in sync with live emoji reactions.',
            badge: 'YouTube only',
            badgeColor: const Color(0xFFFF0000),
            td: td,
            isActive: _activeSession?.type == SyncType.youtube,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => WatchTogetherScreen(coupleId: widget.coupleId))),
          ),
          const SizedBox(height: 32),

          // ── Explainer ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: td.surface,
              borderRadius: BorderRadius.circular(td.cardRadius),
              border: Border.all(color: td.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How sync works', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: td.textOnSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 8),
              Text(
                'One partner is the "conductor" — they control play, pause, and skip. '
                'The other automatically follows within 3 seconds. Either partner can take the conductor role at any time.',
                style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.45), height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  void _rejoinSession(BuildContext context, SyncSession session) {
    switch (session.type) {
      case SyncType.radio:
        Navigator.push(context, petalBloomRoute(builder: (_) => RadioRoomScreen(coupleId: widget.coupleId)));
      case SyncType.youtube:
        Navigator.push(context, petalBloomRoute(builder: (_) => WatchTogetherScreen(coupleId: widget.coupleId)));
      case SyncType.music:
        Navigator.push(context, petalBloomRoute(builder: (_) => const SpotifyTogetherScreen()));
    }
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String myInitial, partnerInitial;
  final AnimationController connectionCtrl, pulseCtrl;
  final HeartSyncThemeData td;
  final SyncSession? activeSession;
  const _HeroSection({
    required this.myInitial, required this.partnerInitial,
    required this.connectionCtrl, required this.pulseCtrl,
    required this.td, required this.activeSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [td.primary.withValues(alpha: td.isLight ? 0.1 : 0.07), td.surface],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.primary.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _HeroAvatar(initial: myInitial, color: td.primary),
          const SizedBox(width: 16),
          SizedBox(width: 80, height: 40,
            child: AnimatedBuilder(
              animation: connectionCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConnectionLinePainter(connectionCtrl.value, td.primary, td.secondary, activeSession != null),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _HeroAvatar(initial: partnerInitial, color: td.secondary),
        ]),
        const SizedBox(height: 16),
        Text(
          activeSession != null ? '✨  Synced right now' : 'Two hearts, one experience',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: activeSession != null ? td.primary : td.textOnSurface.withValues(alpha: 0.5),
          ),
        ),
      ]),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  const _HeroAvatar({required this.initial, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.5), width: 2.5),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)],
    ),
    child: Center(child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22))),
  );
}

class _ConnectionLinePainter extends CustomPainter {
  final double t;
  final Color c1, c2;
  final bool isActive;
  _ConnectionLinePainter(this.t, this.c1, this.c2, this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Base line
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), Paint()
      ..color = c1.withValues(alpha: 0.2)
      ..strokeWidth = 2);
    if (!isActive) {
      // Pulsing dot
      final x = (t % 1.0) * size.width;
      canvas.drawCircle(Offset(x, cy), 4, Paint()..color = c1.withValues(alpha: 0.8));
      canvas.drawCircle(Offset(x, cy), 8, Paint()..color = c1.withValues(alpha: 0.15));
    } else {
      // Active: multiple dots
      for (int i = 0; i < 3; i++) {
        final x = ((t + i / 3.0) % 1.0) * size.width;
        final opa = math.sin((t + i / 3.0) * math.pi).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(x, cy), 4, Paint()..color = c1.withValues(alpha: opa * 0.9));
      }
    }
    // Heart at center
    final heartPath = Path();
    final r = 7.0;
    heartPath.moveTo(cx, cy + r * 0.8);
    heartPath.cubicTo(cx - r * 1.4, cy, cx - r * 1.4, cy - r * 1.2, cx, cy - r * 0.5);
    heartPath.cubicTo(cx + r * 1.4, cy - r * 1.2, cx + r * 1.4, cy, cx, cy + r * 0.8);
    canvas.drawPath(heartPath, Paint()
      ..color = c1.withValues(alpha: isActive ? 0.9 : 0.4)
      ..style = PaintingStyle.fill);
  }

  @override bool shouldRepaint(_ConnectionLinePainter old) => old.t != t || old.isActive != isActive;
}

// ─── Active Session Banner ────────────────────────────────────────────────────

class _ActiveSessionBanner extends StatelessWidget {
  final SyncSession session;
  final HeartSyncThemeData td;
  final String coupleId;
  final VoidCallback onRejoin;
  const _ActiveSessionBanner({required this.session, required this.td, required this.coupleId, required this.onRejoin});

  String get _label => switch (session.type) {
    SyncType.radio   => '📻 Couple Radio is playing',
    SyncType.youtube => '🎬 Watch Together is active',
    SyncType.music   => '🎧 Spotify sync is running',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onRejoin,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: td.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.primary.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Expanded(child: Text(_label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: td.primary))),
        Text('Rejoin ›', style: TextStyle(fontSize: 12, color: td.primary, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ─── Sync Card ────────────────────────────────────────────────────────────────

class _SyncCard extends StatefulWidget {
  final String emoji, title, subtitle, badge;
  final Color badgeColor;
  final HeartSyncThemeData td;
  final bool isActive;
  final VoidCallback onTap;
  const _SyncCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.badge, required this.badgeColor, required this.td,
    required this.isActive, required this.onTap,
  });
  @override State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final td = widget.td;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.isActive ? td.primary.withValues(alpha: 0.08) : td.surface,
            borderRadius: BorderRadius.circular(td.cardRadius),
            border: Border.all(
              color: widget.isActive ? td.primary.withValues(alpha: 0.4) : td.border,
              width: widget.isActive ? 1.5 : 1,
            ),
            boxShadow: widget.isActive
                ? [BoxShadow(color: td.primary.withValues(alpha: 0.15), blurRadius: 16)]
                : td.isLight ? [BoxShadow(color: td.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: widget.badgeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.badgeColor.withValues(alpha: 0.25)),
              ),
              child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: td.textOnSurface)),
                if (widget.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: td.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: td.primary, letterSpacing: 0.5)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(widget.subtitle, style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.45), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.badgeColor.withValues(alpha: 0.25)),
                ),
                child: Text(widget.badge, style: TextStyle(fontSize: 10, color: widget.badgeColor, fontWeight: FontWeight.w600)),
              ),
            ])),
            Icon(Icons.chevron_right, color: td.textOnSurface.withValues(alpha: 0.3), size: 18),
          ]),
        ),
      ),
    );
  }
}
