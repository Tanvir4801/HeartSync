import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../repository/auth_repository.dart';

class CoupleLinkingScreen extends StatefulWidget {
  final String uid;
  final String email;
  const CoupleLinkingScreen({super.key, required this.uid, required this.email});
  @override
  State<CoupleLinkingScreen> createState() => _CoupleLinkingScreenState();
}

class _CoupleLinkingScreenState extends State<CoupleLinkingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _codeCtrl = TextEditingController();
  final _repo = AuthRepository();
  DateTime _anniversary = DateTime.now().subtract(const Duration(days: 365));
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSpace() async {
    setState(() { _loading = true; _error = null; });
    try {
      final coupleId = await _repo.createCoupleSpace(widget.uid, widget.email, _anniversary);
      await _showInviteCode(coupleId);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showInviteCode(String coupleId) async {
    final snap = await FirestoreService().coupleDoc(coupleId).get();
    final code = (snap.data() as Map<String, dynamic>?)?['inviteCode'] as String? ?? '';
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Your Invite Code', style: TextStyle(color: Color(0xFFF0F0F6))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Share this code with your partner so they can join your couple space.',
            style: TextStyle(color: Color(0xFF8888A8)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE05C7E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE05C7E).withOpacity(0.4)),
            ),
            child: Text(
              code,
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFFE05C7E), letterSpacing: 6),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Color(0xFFE05C7E))),
          )
        ],
      ),
    );
  }

  Future<void> _joinSpace() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a valid 6-character code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final coupleId = await _repo.joinCoupleSpace(widget.uid, widget.email, code);
      if (coupleId == null) {
        setState(() { _error = 'Invalid or already used invite code.'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAnniversary() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversary,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) setState(() => _anniversary = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Couple Space'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Create New'), Tab(text: 'Join Existing')],
          indicatorColor: const Color(0xFFE05C7E),
          labelColor: const Color(0xFFE05C7E),
          unselectedLabelColor: const Color(0xFF8888A8),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _CreateTab(
            loading: _loading,
            error: _error,
            anniversary: _anniversary,
            onPickDate: _pickAnniversary,
            onCreate: _createSpace,
          ),
          _JoinTab(
            ctrl: _codeCtrl,
            loading: _loading,
            error: _error,
            onJoin: _joinSpace,
          ),
        ],
      ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final DateTime anniversary;
  final VoidCallback onPickDate;
  final VoidCallback onCreate;
  const _CreateTab({
    required this.loading,
    this.error,
    required this.anniversary,
    required this.onPickDate,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Start a new couple space',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text("You'll get an invite code to share with your partner.",
            style: TextStyle(color: Color(0xFF8888A8))),
        const SizedBox(height: 28),
        const Text('Anniversary Date',
            style: TextStyle(fontSize: 13, color: Color(0xFF8888A8))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF23232F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E2E3E)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today, color: Color(0xFFE05C7E), size: 18),
              const SizedBox(width: 10),
              Text(
                '${anniversary.year}-${anniversary.month.toString().padLeft(2, '0')}-${anniversary.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFFF0F0F6)),
              ),
            ]),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
        ],
        const SizedBox(height: 24),
        loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)))
            : ElevatedButton(onPressed: onCreate, child: const Text('Create Couple Space')),
      ]),
    );
  }
}

class _JoinTab extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onJoin;
  const _JoinTab({required this.ctrl, required this.loading, this.error, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Join your partner',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text("Enter the 6-character invite code from your partner.",
            style: TextStyle(color: Color(0xFF8888A8))),
        const SizedBox(height: 28),
        TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 6, color: Color(0xFFE05C7E)),
          decoration: const InputDecoration(labelText: 'Invite Code', counterText: ''),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
        ],
        const SizedBox(height: 24),
        loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)))
            : ElevatedButton(onPressed: onJoin, child: const Text('Join Couple Space')),
      ]),
    );
  }
}
