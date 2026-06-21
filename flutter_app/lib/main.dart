import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/couple_linking_screen.dart';
import 'shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HeartSyncApp());
}

class HeartSyncApp extends StatelessWidget {
  const HeartSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartSync',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFE05C7E), size: 48),
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: Color(0xFFE05C7E)),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData || snap.data == null) {
          return const LoginScreen();
        }
        return _CoupleGate(uid: snap.data!.uid, email: snap.data!.email ?? '');
      },
    );
  }
}

class _CoupleGate extends StatefulWidget {
  final String uid;
  final String email;
  const _CoupleGate({required this.uid, required this.email});
  @override
  State<_CoupleGate> createState() => _CoupleGateState();
}

class _CoupleGateState extends State<_CoupleGate> {
  final _repo = AuthRepository();
  String? _coupleId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkCouple();
  }

  Future<void> _checkCouple() async {
    final id = await _repo.getExistingCoupleId(widget.uid);
    if (mounted) setState(() { _coupleId = id; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E))),
      );
    }
    if (_coupleId == null) {
      return CoupleLinkingScreen(uid: widget.uid, email: widget.email);
    }
    return MainShell(coupleId: _coupleId!);
  }
}
