import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.duskIndigo,
      body: Stack(children: [
        const FloatingHearts(count: 14),
        SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Logo
                    HeartbeatPulse(child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.dawnAmber, AppTheme.horizonRose], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: AppTheme.dawnAmber.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: const Center(child: Text('❤️', style: TextStyle(fontSize: 44))),
                    )),
                    const SizedBox(height: 20),
                    const Text('HeartSync', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Fraunces', color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Every Heartbeat, Together.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 0.04)),

                    const SizedBox(height: 40),

                    // Email
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.textMuted),
                        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppTheme.textMuted), onPressed: () => setState(() => _obscure = !_obscure)),
                      ),
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Button
                    _loading
                      ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.dawnAmber))
                      : GlowButton(label: 'Sign In', icon: Icons.favorite_rounded, onTap: _login, colors: const [AppTheme.dawnAmber, AppTheme.horizonRose]),

                    const SizedBox(height: 20),

                    // Sign up
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: const Text("Don't have an account? Create one", style: TextStyle(color: AppTheme.horizonRose, fontSize: 13)),
                    ),

                    const SizedBox(height: 32),

                    // Bottom bar decoration
                    HorizonLine(progress: 1.0, colors: const [AppTheme.dawnAmber, AppTheme.horizonRose, AppTheme.lavenderDusk]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
