import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/couple_linking_screen.dart';
import 'shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const HeartSyncApp(),
    ),
  );
}

class HeartSyncApp extends StatelessWidget {
  const HeartSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'HeartSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (!snap.hasData || snap.data == null) {
          return const LoginScreen();
        }
        return _CoupleGate(uid: snap.data!.uid, email: snap.data!.email ?? '');
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.7, curve: Curves.easeIn)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.duskIndigo,
      body: Stack(children: [
        const FloatingHearts(count: 12),
        Center(child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(scale: _scale, child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.dawnAmber, AppTheme.horizonRose]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppTheme.dawnAmber.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: const Center(child: Text('❤️', style: TextStyle(fontSize: 48))),
            )),
            const SizedBox(height: 24),
            FadeTransition(opacity: _fade, child: Column(children: [
              const Text('HeartSync', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Fraunces', color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Every Heartbeat, Together.', style: TextStyle(fontSize: 15, color: AppTheme.textMuted, letterSpacing: 0.04)),
              const SizedBox(height: 32),
              SizedBox(width: 32, height: 32, child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.dawnAmber.withValues(alpha: 0.6),
              )),
            ])),
          ]),
        )),
      ]),
    );
  }
}

class _CoupleGate extends StatefulWidget {
  final String uid, email;
  const _CoupleGate({required this.uid, required this.email});
  @override
  State<_CoupleGate> createState() => _CoupleGateState();
}

class _CoupleGateState extends State<_CoupleGate> {
  final _repo = AuthRepository();
  String? _coupleId;
  bool _loading = true;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final id = await _repo.getExistingCoupleId(widget.uid);
    if (mounted) setState(() { _coupleId = id; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();
    if (_coupleId == null) return CoupleLinkingScreen(uid: widget.uid, email: widget.email);
    return MainShell(coupleId: _coupleId!);
  }
}
