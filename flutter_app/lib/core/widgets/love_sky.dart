import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Sky Phase ────────────────────────────────────────────────────────────────

enum SkyPhase { morning, day, evening, night }

SkyPhase currentSkyPhase() {
  final h = DateTime.now().hour;
  if (h >= 5  && h < 11) return SkyPhase.morning;
  if (h >= 11 && h < 17) return SkyPhase.day;
  if (h >= 17 && h < 21) return SkyPhase.evening;
  return SkyPhase.night;
}

// ─── Mood Aura (output from mood reading) ────────────────────────────────────

enum MoodAura { none, happy, romantic, missingYou, excited }

MoodAura emojiToAura(String? emoji) {
  return switch (emoji) {
    '😊'        => MoodAura.happy,
    '😍' || '🫶' => MoodAura.romantic,
    '🥺'        => MoodAura.missingYou,
    '😤'        => MoodAura.excited,
    _           => MoodAura.none,
  };
}

// ─── Fixed star positions (deterministic) ────────────────────────────────────

final _regularStars = List.generate(30, (i) => Offset(
  (i * 37 + 13) % 100 / 100.0,
  (i * 53 + 7)  % 80  / 100.0,
));

// 8 stars forming a heart shape
const _constellationPoints = [
  Offset(0.50, 0.22), Offset(0.62, 0.17), Offset(0.70, 0.27),
  Offset(0.63, 0.38), Offset(0.50, 0.48), Offset(0.37, 0.38),
  Offset(0.30, 0.27), Offset(0.38, 0.17),
];

// ─── LoveSkyBackground ───────────────────────────────────────────────────────

class LoveSkyBackground extends StatefulWidget {
  final Widget child;
  final MoodAura moodOverride;
  final bool isAnniversary;

  const LoveSkyBackground({
    super.key,
    required this.child,
    this.moodOverride = MoodAura.none,
    this.isAnniversary = false,
  });

  @override
  State<LoveSkyBackground> createState() => _LoveSkyBackgroundState();
}

class _LoveSkyBackgroundState extends State<LoveSkyBackground> with TickerProviderStateMixin {
  late SkyPhase _phase;
  late AnimationController _particleCtrl;
  late AnimationController _constellationCtrl;
  Timer? _phaseTimer;
  Timer? _constellationTimer;
  bool _constellationShowing = false;

  @override
  void initState() {
    super.initState();
    _phase = currentSkyPhase();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _constellationCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _phaseTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      final p = currentSkyPhase();
      if (p != _phase && mounted) setState(() => _phase = p);
    });

    _scheduleConstellation();
  }

  void _scheduleConstellation() {
    _constellationTimer?.cancel();
    _constellationTimer = Timer(const Duration(minutes: 3), () async {
      if (!mounted) return;
      setState(() => _constellationShowing = true);
      await _constellationCtrl.forward(from: 0);
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      await _constellationCtrl.reverse();
      if (mounted) {
        setState(() => _constellationShowing = false);
        _scheduleConstellation();
      }
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _constellationCtrl.dispose();
    _phaseTimer?.cancel();
    _constellationTimer?.cancel();
    super.dispose();
  }

  List<Color> get _skyGradient {
    if (widget.isAnniversary) return [const Color(0xFF1A1000), const Color(0xFF3D2800), const Color(0xFF1A1000)];
    return switch (widget.moodOverride) {
      MoodAura.missingYou => [const Color(0xFF0D0A1F), const Color(0xFF1B1836), const Color(0xFF1A0A2E)],
      MoodAura.romantic   => [const Color(0xFF1A0812), const Color(0xFF2D1020), const Color(0xFF1A0812)],
      MoodAura.none       => switch (_phase) {
        SkyPhase.morning => [const Color(0xFF1A1030), const Color(0xFF2D1845), const Color(0xFF3D2045)],
        SkyPhase.day     => [const Color(0xFF1B1836), const Color(0xFF252440)],
        SkyPhase.evening => [const Color(0xFF1A0D08), const Color(0xFF3D1C10), const Color(0xFF2A1018)],
        SkyPhase.night   => [const Color(0xFF0D0A1F), const Color(0xFF1B1836), const Color(0xFF0A051A)],
      },
      _ => [const Color(0xFF1B1836), const Color(0xFF252440)],
    };
  }

  // Priority: anniversary > strong mood > sky time
  // Only ONE particle system active at a time. Day sky has none.
  Widget? get _particles {
    if (widget.isAnniversary) return _AnniversaryParticles(ctrl: _particleCtrl);
    if (widget.moodOverride == MoodAura.missingYou) return _RainParticles(ctrl: _particleCtrl);
    if (widget.moodOverride == MoodAura.romantic || widget.moodOverride == MoodAura.happy) return _PetalParticles(ctrl: _particleCtrl);
    if (widget.moodOverride == MoodAura.excited) return _SparkleParticles(ctrl: _particleCtrl);
    // Sky time particles — Day has none
    return switch (_phase) {
      SkyPhase.morning => _BirdParticles(ctrl: _particleCtrl),
      SkyPhase.evening => _PetalParticles(ctrl: _particleCtrl),
      SkyPhase.night   => _StarField(
        ctrl: _particleCtrl,
        constellationCtrl: _constellationCtrl,
        showConstellation: _constellationShowing,
      ),
      SkyPhase.day => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Sky gradient
      Positioned.fill(child: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: _skyGradient,
        )),
      )),

      // ONE particle system
      if (_particles != null) Positioned.fill(child: _particles!),

      // Mood aura overlay (very low opacity tint)
      if (widget.moodOverride != MoodAura.none || widget.isAnniversary)
        Positioned.fill(child: _MoodAuraOverlay(mood: widget.moodOverride, isAnniversary: widget.isAnniversary)),

      // Candle mode: after 10pm, add warm amber tint
      if (DateTime.now().hour >= 22)
        Positioned.fill(child: IgnorePointer(child: Container(
          color: const Color(0xFFF3C98B).withValues(alpha: 0.03),
        ))),

      widget.child,
    ]);
  }
}

// ─── Heartbeat Glow ──────────────────────────────────────────────────────────

class HeartbeatGlow extends StatefulWidget {
  final Color color;
  const HeartbeatGlow({super.key, this.color = const Color(0xFFE8A598)});
  @override
  State<HeartbeatGlow> createState() => _HeartbeatGlowState();
}

class _HeartbeatGlowState extends State<HeartbeatGlow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    // Double-beat cycle: beat → rest → beat → long rest
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.08), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.05), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.08), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.05), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.05),            weight: 70),
    ]).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, __) => IgnorePointer(child: Container(
      decoration: BoxDecoration(gradient: RadialGradient(
        center: Alignment.center, radius: 0.75,
        colors: [widget.color.withValues(alpha: _opacity.value), Colors.transparent],
      )),
    )),
  );
}

// ─── Mood Aura Overlay ───────────────────────────────────────────────────────

class _MoodAuraOverlay extends StatelessWidget {
  final MoodAura mood;
  final bool isAnniversary;
  const _MoodAuraOverlay({required this.mood, required this.isAnniversary});

  List<Color> get _colors {
    if (isAnniversary) return [const Color(0xFFF3C98B), const Color(0xFFE8A598)];
    return switch (mood) {
      MoodAura.happy      => [const Color(0xFFE8A598), const Color(0xFFF3C98B)],
      MoodAura.romantic   => [const Color(0xFFE8A598), const Color(0xFFA78BFA)],
      MoodAura.missingYou => [const Color(0xFFA78BFA), const Color(0xFF1B1836)],
      MoodAura.excited    => [const Color(0xFFF3C98B), const Color(0xFFE8A598)],
      MoodAura.none       => [Colors.transparent, Colors.transparent],
    };
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(
    decoration: BoxDecoration(gradient: RadialGradient(
      center: Alignment.topCenter, radius: 1.2,
      colors: [_colors.first.withValues(alpha: 0.07), _colors.last.withValues(alpha: 0.03), Colors.transparent],
    )),
  ));
}

// ─── Particle Systems ─────────────────────────────────────────────────────────

// Morning birds
class _BirdParticles extends StatelessWidget {
  final AnimationController ctrl;
  const _BirdParticles({required this.ctrl});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _BirdPainter(ctrl.value), size: Size.infinite),
  ));
}

class _BirdPainter extends CustomPainter {
  final double t;
  _BirdPainter(this.t);
  static const _birds = [(0.10, 0.10, 0.08), (0.35, 0.22, 0.06), (0.20, 0.34, 0.07), (0.55, 0.14, 0.05)];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFF8F6F2).withValues(alpha: 0.22)..strokeWidth = 1.3..style = PaintingStyle.stroke;
    for (final b in _birds) {
      final x = ((b.$1 + t * b.$3) % 1.15) * size.width;
      final y = b.$2 * size.height;
      final path = Path()
        ..moveTo(x - 11, y + 5)
        ..cubicTo(x - 5, y, x - 1, y - 4, x, y - 6)
        ..cubicTo(x + 1, y - 4, x + 5, y, x + 11, y + 5);
      canvas.drawPath(path, p);
    }
  }
  @override bool shouldRepaint(_BirdPainter old) => old.t != t;
}

// Petals (evening + romantic/happy mood)
class _PetalParticles extends StatelessWidget {
  final AnimationController ctrl;
  const _PetalParticles({required this.ctrl});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _PetalPainter(ctrl.value), size: Size.infinite),
  ));
}

class _PetalPainter extends CustomPainter {
  final double t;
  _PetalPainter(this.t);
  static const _petals = [(0.12, 0.3, 0.09, 1.2), (0.33, 0.7, 0.07, 0.8), (0.58, 0.1, 0.08, 1.5), (0.75, 0.5, 0.06, 1.0), (0.90, 0.25, 0.10, 0.9)];
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _petals.length; i++) {
      final p = _petals[i];
      final y = ((p.$2 + t * p.$3) % 1.1) * size.height;
      final sway = math.sin(t * math.pi * 2 + i) * 0.04;
      final x = (p.$1 + sway) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.$4 * math.pi * 2);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 5),
        Paint()..color = const Color(0xFFE8A598).withValues(alpha: 0.38));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_PetalPainter old) => old.t != t;
}

// Night stars + heart constellation
class _StarField extends StatelessWidget {
  final AnimationController ctrl, constellationCtrl;
  final bool showConstellation;
  const _StarField({required this.ctrl, required this.constellationCtrl, required this.showConstellation});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: Listenable.merge([ctrl, constellationCtrl]),
    builder: (_, __) => CustomPaint(
      painter: _StarPainter(ctrl.value, showConstellation ? constellationCtrl.value : 0.0),
      size: Size.infinite,
    ),
  ));
}

class _StarPainter extends CustomPainter {
  final double twinkle, constellationOpa;
  _StarPainter(this.twinkle, this.constellationOpa);
  @override
  void paint(Canvas canvas, Size size) {
    // Regular stars
    for (int i = 0; i < _regularStars.length; i++) {
      final pos = Offset(_regularStars[i].dx * size.width, _regularStars[i].dy * size.height);
      final t = 0.3 + (math.sin(twinkle * math.pi * 2 * (1 + i * 0.11) + i) * 0.28).abs();
      canvas.drawCircle(pos, 0.8 + (i % 3) * 0.45, Paint()..color = const Color(0xFFF8F6F2).withValues(alpha: t));
    }
    // Constellation stars (brighter, rose-gold)
    for (final s in _constellationPoints) {
      final pos = Offset(s.dx * size.width, s.dy * size.height * 0.8);
      canvas.drawCircle(pos, 5.0, Paint()..color = const Color(0xFFE8A598).withValues(alpha: 0.15));
      canvas.drawCircle(pos, 2.2, Paint()..color = const Color(0xFFE8A598).withValues(alpha: 0.85));
    }
    // Constellation connecting lines (fade in/out)
    if (constellationOpa > 0) {
      final lp = Paint()
        ..color = const Color(0xFFE8A598).withValues(alpha: constellationOpa * 0.35)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      final pts = _constellationPoints.map((s) => Offset(s.dx * size.width, s.dy * size.height * 0.8)).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
      path.close();
      canvas.drawPath(path, lp);
    }
  }
  @override bool shouldRepaint(_StarPainter old) => old.twinkle != twinkle || old.constellationOpa != constellationOpa;
}

// Rain for "missing you"
class _RainParticles extends StatelessWidget {
  final AnimationController ctrl;
  const _RainParticles({required this.ctrl});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _RainPainter(ctrl.value), size: Size.infinite),
  ));
}

class _RainPainter extends CustomPainter {
  final double t;
  _RainPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFA78BFA).withValues(alpha: 0.18)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    for (int i = 0; i < 18; i++) {
      final x = (i * 0.056 + 0.02) * size.width;
      final y = ((t + i * 0.056) % 1.0) * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + 12), p);
    }
  }
  @override bool shouldRepaint(_RainPainter old) => old.t != t;
}

// Sparkles for "excited"
class _SparkleParticles extends StatelessWidget {
  final AnimationController ctrl;
  const _SparkleParticles({required this.ctrl});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _SparklePainter(ctrl.value), size: Size.infinite),
  ));
}

class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 12; i++) {
      final phase = (t + i / 12.0) % 1.0;
      final opa = math.sin(phase * math.pi).clamp(0.0, 1.0);
      if (opa < 0.1) continue;
      final x = (i * 0.085 + 0.04) * size.width;
      final y = (0.15 + math.sin(t * math.pi * 1.3 + i) * 0.12) * size.height;
      canvas.drawCircle(Offset(x, y), 2.0 + opa * 2.5, Paint()..color = const Color(0xFFF3C98B).withValues(alpha: opa * 0.5));
    }
  }
  @override bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// Anniversary golden petals
class _AnniversaryParticles extends StatelessWidget {
  final AnimationController ctrl;
  const _AnniversaryParticles({required this.ctrl});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _AnniversaryPainter(ctrl.value), size: Size.infinite),
  ));
}

class _AnniversaryPainter extends CustomPainter {
  final double t;
  _AnniversaryPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 8; i++) {
      final y = ((t * 0.07 + i * 0.125) % 1.1) * size.height;
      final x = (i * 0.12 + 0.06 + math.sin(t * math.pi + i) * 0.035) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 0.6 + i);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
        Paint()..color = const Color(0xFFF3C98B).withValues(alpha: 0.45));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_AnniversaryPainter old) => old.t != t;
}
