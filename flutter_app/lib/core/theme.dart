import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Romantic Theme System ────────────────────────────────────────────────────

enum RomanticTheme { sweetheart }

class HeartSyncThemeData {
  final RomanticTheme id;
  final String name;
  final String emoji;
  final Color background;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;
  final List<Color> heartColors;
  // Light-theme / Sweetheart fields
  final bool isLight;
  final double cardRadius;
  final Color textOnSurface;
  final Color shimmerBase;
  final Color shimmerHighlight;
  // Badge palette (7 colours for FeatureCardCarousel)
  final List<Color> badgeColors;

  const HeartSyncThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.heartColors,
    this.isLight = false,
    this.cardRadius = 16,
    this.textOnSurface = AppTheme.textPrimary,
    this.shimmerBase = AppTheme.surface,
    this.shimmerHighlight = AppTheme.surface2,
    this.badgeColors = const [
      Color(0xFF4ADE80), Color(0xFF9B8AC4), Color(0xFFE8927C),
      Color(0xFF9B8AC4), Color(0xFFF2A65A), Color(0xFFFACC15), Color(0xFFE05C7E),
    ],
  });
}

class AppTheme {
  // ── Static tokens (Sweetheart-first / shared) ─────────────────────────────
  static const duskIndigo   = Color(0xFFF7F1FF);
  static const inkDark      = Color(0xFF4A3B6B);
  static const dawnAmber    = Color(0xFFF4A227);
  static const horizonRose  = Color(0xFFFF9EB5);
  static const lavenderDusk = Color(0xFF9B87F5);
  static const surface      = Color(0xFFFFFBFE);
  static const surface2     = Color(0xFFF3EFFF);
  static const border       = Color(0xFFE2D9FF);
  static const textPrimary  = Color(0xFF4A3B6B);
  static const textMuted    = Color(0xFF8E7BAF);
  static const success      = Color(0xFF5CCF9F);
  static const warning      = Color(0xFFF6B24B);
  static const danger       = Color(0xFFE96A82);
  static const roseGold     = Color(0xFFE05C7E);
  static const softPeach    = Color(0xFFFFD6C7);
  static const deepPurple   = Color(0xFF7B61D1);

  // ── Sweetheart static tokens ─────────────────────────────────────────────
  static const sweetLavenderPop  = Color(0xFF9B87F5);
  static const sweetCoralBlush   = Color(0xFFFF9EB5);
  static const sweetSunshine     = Color(0xFFFFD66B);
  static const sweetSkyMint      = Color(0xFF8CE0C9);
  static const sweetSoftPeach    = Color(0xFFFFC9A8);
  static const sweetPlumInk      = Color(0xFF4A3B6B);
  static const sweetCloudWhite   = Color(0xFFFFFBFE);
  static const sweetLavMist      = Color(0xFFF3EFFF);
  static const sweetBlushMist    = Color(0xFFFDEEF6);

  // ── Theme catalogue ───────────────────────────────────────────────────────
  static const Map<RomanticTheme, HeartSyncThemeData> themes = {
    RomanticTheme.sweetheart: HeartSyncThemeData(
      id: RomanticTheme.sweetheart, name: 'Sweetheart', emoji: '🍬',
      background: Color(0xFFF3EFFF),
      surface: Color(0xFFFFFBFE),
      surface2: Color(0xFFF0EBFF),
      border: Color(0xFFE2D9FF),
      primary: Color(0xFF9B87F5),
      secondary: Color(0xFFFF9EB5),
      accent: Color(0xFFFFD66B),
      gradient: [Color(0xFFF3EFFF), Color(0xFFFDEEF6), Color(0xFFF3EFFF)],
      heartColors: [Color(0xFF9B87F5), Color(0xFFFF9EB5), Color(0xFFFFD66B)],
      isLight: true,
      cardRadius: 28,
      textOnSurface: Color(0xFF4A3B6B),
      shimmerBase: Color(0xFFE7DBFF),
      shimmerHighlight: Color(0xFFFDF7FF),
      badgeColors: [
        Color(0xFF8CE0C9), Color(0xFF9B87F5), Color(0xFFFF9EB5),
        Color(0xFFFFD66B), Color(0xFF8CE0C9), Color(0xFF9B87F5), Color(0xFFFF9EB5),
      ],
    ),
  };

  static List<HeartSyncThemeData> get availableThemes => [themes[RomanticTheme.sweetheart]!];

  static HeartSyncThemeData themeData(RomanticTheme t) => themes[t]!;

  static ThemeData forThemeData(HeartSyncThemeData td) {
    if (td.isLight) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: td.background,
        colorScheme: ColorScheme.light(
          primary: td.primary,
          secondary: td.secondary,
          surface: td.surface,
          error: danger,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: td.textOnSurface,
        ),
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          backgroundColor: td.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: td.textOnSurface, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
          iconTheme: IconThemeData(color: td.textOnSurface),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: td.surface,
          indicatorColor: td.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: td.primary);
            return TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.5));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return IconThemeData(color: td.primary, size: 22);
            return IconThemeData(color: td.textOnSurface.withValues(alpha: 0.5), size: 22);
          }),
        ),
        cardTheme: CardThemeData(
          color: td.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(td.cardRadius), side: BorderSide(color: td.border)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: td.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(td.cardRadius), borderSide: BorderSide(color: td.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(td.cardRadius), borderSide: BorderSide(color: td.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(td.cardRadius), borderSide: BorderSide(color: td.primary, width: 2)),
          hintStyle: TextStyle(color: td.textOnSurface.withValues(alpha: 0.45)),
          labelStyle: TextStyle(color: td.textOnSurface.withValues(alpha: 0.55)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: td.primary, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        dividerTheme: DividerThemeData(color: td.border, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: td.surface,
          contentTextStyle: TextStyle(color: td.textOnSurface),
        ),
      );
    }

    // Dark themes
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: td.background,
      colorScheme: ColorScheme.dark(
        primary: td.primary,
        secondary: td.secondary,
        surface: td.surface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: td.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: td.surface,
        indicatorColor: td.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: td.primary);
          return const TextStyle(fontSize: 11, color: textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: td.primary, size: 22);
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: td.surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(td.cardRadius), side: BorderSide(color: td.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: td.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: td.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: td.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: td.primary, width: 2)),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: td.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: td.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: td.surface2,
        contentTextStyle: const TextStyle(color: textPrimary),
      ),
    );
  }
}

// ─── Theme provider ──────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  RomanticTheme _current = RomanticTheme.sweetheart;
  RomanticTheme get current => _current;
  HeartSyncThemeData get data => AppTheme.themeData(_current);

  void setTheme(RomanticTheme t) {
    _current = t;
    notifyListeners();
  }
}

// ─── Clay Card (Sweetheart claymorphism, falls back to standard on dark) ─────

class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? overrideSurface;
  const ThemedCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.overrideSurface});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    if (td.isLight) {
      return Container(
        decoration: BoxDecoration(
          color: overrideSurface ?? td.surface,
          borderRadius: BorderRadius.circular(td.cardRadius),
          border: Border.all(color: td.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: td.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: 0),
          ],
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: overrideSurface ?? td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ─── Widget Library ──────────────────────────────────────────────────────────

/// Animated horizon gradient line / progress bar
class HorizonLine extends StatelessWidget {
  final double progress;
  final double height;
  final List<Color>? colors;
  const HorizonLine({super.key, this.progress = 1.0, this.height = 2, this.colors});

  @override
  Widget build(BuildContext context) {
    final cs = colors ?? const [AppTheme.lavenderDusk, AppTheme.horizonRose, AppTheme.dawnAmber];
    return SizedBox(
      height: height, width: double.infinity,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(colors: cs),
          borderRadius: BorderRadius.circular(height / 2),
        )),
      ),
    );
  }
}

/// Glass card with subtle blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? tintColor;
  const GlassCard({super.key, required this.child, this.padding, this.tintColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (tintColor ?? AppTheme.surface).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

/// Heartbeat pulse animation wrapper
class HeartbeatPulse extends StatefulWidget {
  final Widget child;
  final Duration period;
  const HeartbeatPulse({super.key, required this.child, this.period = const Duration(milliseconds: 1400)});
  @override
  State<HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<HeartbeatPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.95), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.14), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0),  weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0,  end: 1.0),  weight: 55),
    ]).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

/// Floating hearts background
class FloatingHearts extends StatefulWidget {
  final List<Color>? colors;
  final int count;
  const FloatingHearts({super.key, this.colors, this.count = 10});
  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _pos;
  late List<Animation<double>> _opa;
  final _hearts = <_Particle>[];

  @override
  void initState() {
    super.initState();
    final colors = widget.colors ?? const [AppTheme.dawnAmber, AppTheme.horizonRose, AppTheme.lavenderDusk];
    _ctrls = List.generate(widget.count, (i) =>
      AnimationController(vsync: this, duration: Duration(milliseconds: 4000 + (i * 313) % 2500)));
    _pos = _ctrls.map((c) => Tween(begin: 1.1, end: -0.15).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    _opa = _ctrls.map((c) => TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.5), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 20),
    ]).animate(c)).toList();
    for (int i = 0; i < widget.count; i++) {
      _hearts.add(_Particle(x: (i * 0.1 + 0.03) % 1.0, size: 8 + (i * 4.1) % 14, color: colors[i % colors.length], phase: i.toDouble()));
      Future.delayed(Duration(milliseconds: (i * 350) % 3500), () { if (mounted) _ctrls[i].repeat(); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: Listenable.merge(_ctrls),
    builder: (_, __) => CustomPaint(
      painter: _HeartsPainter(_hearts, _pos.map((a) => a.value).toList(), _opa.map((a) => a.value).toList()),
      size: Size.infinite,
    ),
  ));
}

class _Particle {
  final double x, size, phase;
  final Color color;
  const _Particle({required this.x, required this.size, required this.color, required this.phase});
}

class _HeartsPainter extends CustomPainter {
  final List<_Particle> hearts;
  final List<double> positions, opacities;
  _HeartsPainter(this.hearts, this.positions, this.opacities);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < hearts.length && i < positions.length; i++) {
      final h = hearts[i];
      final yFrac = positions[i];
      final sway = (yFrac * 6.28 + h.phase) * 0.05;
      final x = ((h.x + sway).clamp(0.0, 1.0)) * size.width;
      final y = yFrac * size.height;
      final paint = Paint()..color = h.color.withValues(alpha: opacities[i].clamp(0.0, 1.0));
      _drawHeart(canvas, Offset(x, y), h.size, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * 0.35)
      ..cubicTo(c.dx - s * 0.5, c.dy, c.dx - s * 0.55, c.dy - s * 0.6, c.dx, c.dy - s * 0.25)
      ..cubicTo(c.dx + s * 0.55, c.dy - s * 0.6, c.dx + s * 0.5, c.dy, c.dx, c.dy + s * 0.35)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_HeartsPainter old) => true;
}

/// Confetti burst overlay
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});
  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _ps = <_CP>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    const cols = [AppTheme.dawnAmber, AppTheme.horizonRose, AppTheme.lavenderDusk, AppTheme.success, AppTheme.warning, AppTheme.roseGold];
    for (int i = 0; i < 50; i++) {
      _ps.add(_CP(
        x: 0.5 + (i % 7 - 3) * 0.07,
        vx: ((i * 0.41) % 1.0 - 0.5) * 0.9,
        vy: -0.9 - (i * 0.11) % 0.6,
        color: cols[i % cols.length],
        size: 5 + (i * 1.3) % 7,
        rot: (i * 0.71) % 3.14,
      ));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_ps, _ctrl.value), size: Size.infinite),
  ));
}

class _CP { final double x, vx, vy, size, rot; final Color color; const _CP({required this.x, required this.vx, required this.vy, required this.size, required this.rot, required this.color}); }

class _ConfettiPainter extends CustomPainter {
  final List<_CP> ps; final double t;
  _ConfettiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final grav = 0.6 * t * t;
      final cx = (p.x + p.vx * t) * size.width;
      final cy = (0.35 + p.vy * t + grav) * size.height;
      final opa = (1.0 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rot + t * 5);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), Paint()..color = p.color.withValues(alpha: opa));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

/// Shimmer loading placeholder — theme-aware
class ShimmerBox extends StatefulWidget {
  final double width, height;
  final double radius;
  final Color? baseColor;
  final Color? highlightColor;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8, this.baseColor, this.highlightColor});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final base = widget.baseColor ?? td.shimmerBase;
    final hi   = widget.highlightColor ?? td.shimmerHighlight;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value, 0), end: Alignment(_anim.value + 1, 0),
            colors: [base, hi, base],
          ),
        ),
      ),
    );
  }
}

/// Gradient glow button
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final IconData? icon;
  final bool pill;
  const GlowButton({super.key, required this.label, this.onTap, this.colors, this.icon, this.pill = false});

  @override
  Widget build(BuildContext context) {
    final cs = colors ?? const [AppTheme.dawnAmber, AppTheme.horizonRose];
    final radius = pill ? 100.0 : 16.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54, alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: cs),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: cs.first.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}
