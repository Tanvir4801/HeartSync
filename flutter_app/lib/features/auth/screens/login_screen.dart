import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../repository/auth_repository.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideIn = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _enterCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'user-not-found':    return 'No account found with this email.';
      case 'wrong-password':    return 'Incorrect password.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default:                  return 'Sign in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final isSweetheart = td.isLight;

    return Scaffold(
      backgroundColor: td.background,
      body: Stack(children: [
        // Background decoration
        if (!isSweetheart)
          const FloatingHearts(count: 14)
        else
          _SweetheartBubbles(colors: td.heartColors),
        SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: isSweetheart
                      ? _SweetheartLoginBody(
                          emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl,
                          loading: _loading,
                          error: _error,
                          obscure: _obscure,
                          onObscureToggle: () => setState(() => _obscure = !_obscure),
                          onLogin: _login,
                          onSignup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                          td: td,
                        )
                      : _DarkLoginBody(
                          emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl,
                          loading: _loading,
                          error: _error,
                          obscure: _obscure,
                          onObscureToggle: () => setState(() => _obscure = !_obscure),
                          onLogin: _login,
                          onSignup: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                          td: td,
                        ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Dark (existing) login body ─────────────────────────────────────────────────

class _DarkLoginBody extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final bool loading, obscure;
  final String? error;
  final VoidCallback onObscureToggle, onLogin, onSignup;
  final HeartSyncThemeData td;

  const _DarkLoginBody({
    required this.emailCtrl, required this.passCtrl,
    required this.loading, required this.obscure,
    required this.error, required this.onObscureToggle,
    required this.onLogin, required this.onSignup,
    required this.td,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      HeartbeatPulse(child: Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [td.primary, td.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 10))],
        ),
        child: const Center(child: Text('❤️', style: TextStyle(fontSize: 44))),
      )),
      const SizedBox(height: 20),
      Text('HeartSync', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Fraunces', color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text('Every Heartbeat, Together.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 0.04)),
      const SizedBox(height: 40),
      TextField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppTheme.textMuted),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: passCtrl,
        obscureText: obscure,
        onSubmitted: (_) => onLogin(),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.textMuted),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppTheme.textMuted),
            onPressed: onObscureToggle,
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 12),
        _ErrorBox(message: error!),
      ],
      const SizedBox(height: 24),
      loading
          ? SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, color: td.primary))
          : GlowButton(label: 'Sign In', icon: Icons.favorite_rounded, onTap: onLogin, colors: [td.primary, td.secondary]),
      const SizedBox(height: 20),
      TextButton(
        onPressed: onSignup,
        child: Text("Don't have an account? Create one", style: TextStyle(color: td.secondary, fontSize: 13)),
      ),
      const SizedBox(height: 32),
      HorizonLine(progress: 1.0, colors: [td.primary, td.secondary, td.accent]),
    ]);
  }
}

// ── Sweetheart login body ──────────────────────────────────────────────────────

class _SweetheartLoginBody extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final bool loading, obscure;
  final String? error;
  final VoidCallback onObscureToggle, onLogin, onSignup;
  final HeartSyncThemeData td;

  const _SweetheartLoginBody({
    required this.emailCtrl, required this.passCtrl,
    required this.loading, required this.obscure,
    required this.error, required this.onObscureToggle,
    required this.onLogin, required this.onSignup,
    required this.td,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Clay-style logo
      HeartbeatPulse(child: Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [td.primary, td.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: td.primary.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: 2),
          ],
        ),
        child: const Center(child: Text('💜', style: TextStyle(fontSize: 46))),
      )),
      const SizedBox(height: 22),
      Text('Welcome Back 💜', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: td.textOnSurface, height: 1.2)),
      const SizedBox(height: 6),
      Text('Your love story continues here', style: TextStyle(color: td.textOnSurface.withValues(alpha: 0.5), fontSize: 14)),
      const SizedBox(height: 36),

      // Form card
      Container(
        decoration: BoxDecoration(
          color: td.surface,
          borderRadius: BorderRadius.circular(td.cardRadius),
          border: Border.all(color: td.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: td.primary.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _SweetheartField(
            controller: emailCtrl,
            label: 'Email',
            icon: Icons.alternate_email_rounded,
            iconColor: td.primary,
            keyboardType: TextInputType.emailAddress,
            td: td,
          ),
          const SizedBox(height: 14),
          _SweetheartField(
            controller: passCtrl,
            label: 'Password',
            icon: Icons.lock_rounded,
            iconColor: td.secondary,
            obscureText: obscure,
            td: td,
            onSubmitted: (_) => onLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: td.textOnSurface.withValues(alpha: 0.4),
                size: 18,
              ),
              onPressed: onObscureToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ]),
      ),

      if (error != null) ...[
        const SizedBox(height: 12),
        _ErrorBox(message: error!, textColor: const Color(0xFFE05C7E)),
      ],
      const SizedBox(height: 24),
      loading
          ? SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, color: td.primary))
          : SizedBox(
              width: double.infinity,
              child: GlowButton(
                label: 'Sign In',
                icon: Icons.favorite_rounded,
                onTap: onLogin,
                colors: [td.primary, td.secondary],
                pill: true,
              ),
            ),
      const SizedBox(height: 18),
      TextButton(
        onPressed: onSignup,
        child: Text(
          "New here? Create your love story  →",
          style: TextStyle(color: td.primary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: Divider(color: td.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('💕', style: const TextStyle(fontSize: 14)),
        ),
        Expanded(child: Divider(color: td.border)),
      ]),
    ]);
  }
}

class _SweetheartField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final HeartSyncThemeData td;

  const _SweetheartField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.td,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: TextStyle(color: td.textOnSurface, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: td.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 1.5)),
          suffixIcon: suffixIcon,
        ),
      )),
    ]);
  }
}

// ── Shared error box ───────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  final Color? textColor;
  const _ErrorBox({required this.message, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppTheme.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}

// ── Sweetheart floating bubbles (replaces floating hearts on light theme) ──────

class _SweetheartBubbles extends StatefulWidget {
  final List<Color> colors;
  const _SweetheartBubbles({required this.colors});
  @override
  State<_SweetheartBubbles> createState() => _SweetheartBubblesState();
}

class _SweetheartBubblesState extends State<_SweetheartBubbles> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _pos, _opa;

  static const _bubbles = [
    (0.08, 20.0), (0.22, 14.0), (0.55, 18.0), (0.78, 12.0),
    (0.90, 22.0), (0.35, 10.0), (0.68, 16.0), (0.15, 8.0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_bubbles.length, (i) =>
      AnimationController(vsync: this, duration: Duration(milliseconds: 5000 + i * 600)));
    _pos = _ctrls.map((c) => Tween(begin: 1.1, end: -0.15).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    _opa = _ctrls.map((c) => TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.35), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 20),
    ]).animate(c)).toList();
    for (int i = 0; i < _bubbles.length; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () { if (mounted) _ctrls[i].repeat(); });
    }
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: Listenable.merge(_ctrls),
    builder: (_, __) => CustomPaint(
      painter: _BubblePainter(_bubbles, _pos.map((a) => a.value).toList(), _opa.map((a) => a.value).toList(), widget.colors),
      size: Size.infinite,
    ),
  ));
}

class _BubblePainter extends CustomPainter {
  final List<(double, double)> bubbles;
  final List<double> positions, opacities;
  final List<Color> colors;
  _BubblePainter(this.bubbles, this.positions, this.opacities, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < bubbles.length; i++) {
      final (xFrac, radius) = bubbles[i];
      final x = xFrac * size.width;
      final y = positions[i] * size.height;
      final color = colors[i % colors.length].withValues(alpha: opacities[i]);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = Colors.white.withValues(alpha: opacities[i] * 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => true;
}
