import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../../../features/auth/repository/auth_repository.dart';

class ProfileScreen extends StatelessWidget {
  final String coupleId;
  const ProfileScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().coupleDoc(coupleId).snapshots(),
        builder: (_, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final members = List<String>.from(data?['memberEmails'] ?? []);
          final anniversary = (data?['anniversaryDate'] as Timestamp?)?.toDate();
          final inviteCode = data?['inviteCode'] as String? ?? '';
          final streak = data?['streak'] as int? ?? 0;
          final xp = data?['xp'] as int? ?? 0;
          final status = data?['status'] as String? ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Section(title: 'Your Account', children: [
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
                _InfoRow(icon: Icons.badge_outlined, label: 'UID', value: user?.uid.substring(0, 8) ?? '—'),
              ]),
              const SizedBox(height: 20),
              _Section(title: 'Couple Space', children: [
                _InfoRow(icon: Icons.favorite_outline, label: 'Couple ID', value: coupleId.substring(0, 8)),
                _InfoRow(icon: Icons.key_outlined, label: 'Invite Code', value: inviteCode),
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'Anniversary', value: anniversary != null ? '${anniversary.year}-${anniversary.month.toString().padLeft(2,'0')}-${anniversary.day.toString().padLeft(2,'0')}' : '—'),
                _InfoRow(icon: Icons.people_outline, label: 'Members', value: members.join(', ')),
                _InfoRow(icon: Icons.circle_outlined, label: 'Status', value: status),
              ]),
              const SizedBox(height: 20),
              _Section(title: 'Stats', children: [
                _InfoRow(icon: Icons.local_fire_department_outlined, label: 'Streak', value: '$streak days'),
                _InfoRow(icon: Icons.star_outline, label: 'Total XP', value: '$xp XP (Level ${xp ~/ 100})'),
              ]),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
                label: const Text('Sign out', style: TextStyle(color: Color(0xFFF87171))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await AuthRepository().signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8888A8), letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Card(child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(height: 1, indent: 52),
        ],
      ])),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF8888A8)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8888A8))),
        const Spacer(),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
