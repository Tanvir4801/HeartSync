import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../features/auth/repository/auth_repository.dart';

const _badges = [
  ('🔥', '7-Day Streak', 0, 7),
  ('❤️‍🔥', '30-Day Streak', 0, 30),
  ('📸', 'Memory Keeper', 100, 0),
  ('🏆', '100 Memories', 500, 0),
  ('⚡', 'Power Couple', 500, 0),
  ('💎', 'Premium', 0, 0),
];

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
          final isPremium = data?['subscription'] == 'premium';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CoverBanner(coupleId: coupleId, isPremium: isPremium),
              const SizedBox(height: 20),
              _BadgeRow(xp: xp, streak: streak, isPremium: isPremium),
              const SizedBox(height: 20),
              _Section(title: 'Your Account', children: [
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
                _InfoRow(icon: Icons.badge_outlined, label: 'UID', value: user?.uid.substring(0, 8) ?? '—'),
              ]),
              const SizedBox(height: 20),
              _Section(title: 'Couple Space', children: [
                _InfoRow(icon: Icons.favorite_outline, label: 'Couple ID', value: coupleId.length > 8 ? coupleId.substring(0, 8) : coupleId),
                _InfoRow(icon: Icons.key_outlined, label: 'Invite Code', value: inviteCode, mono: true),
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'Anniversary', value: anniversary != null ? '${anniversary.year}-${anniversary.month.toString().padLeft(2, '0')}-${anniversary.day.toString().padLeft(2, '0')}' : '—', mono: true),
                _InfoRow(icon: Icons.people_outline, label: 'Members', value: members.join(', ')),
                _InfoRow(icon: Icons.circle_outlined, label: 'Status', value: status.isEmpty ? 'active' : status),
              ]),
              const SizedBox(height: 20),
              _Section(title: 'Stats', children: [
                _InfoRow(icon: Icons.local_fire_department_outlined, label: 'Streak', value: '$streak days', mono: true),
                _InfoRow(icon: Icons.star_outline, label: 'XP', value: '$xp XP — Level ${xp ~/ 100}', mono: true),
                _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Tier', value: isPremium ? 'Premium ✨' : 'Free'),
              ]),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.danger),
                label: const Text('Sign out', style: TextStyle(color: AppTheme.danger)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async { await AuthRepository().signOut(); },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverBanner extends StatelessWidget {
  final String coupleId;
  final bool isPremium;
  const _CoverBanner({required this.coupleId, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.duskIndigo, AppTheme.horizonRose, AppTheme.dawnAmber],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.duskIndigo, AppTheme.horizonRose, AppTheme.dawnAmber])))),
        if (isPremium) Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
          child: const Text('PREMIUM ✨', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.dawnAmber)))),
        const Center(child: Text('💕', style: TextStyle(fontSize: 48))),
      ]),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final int xp;
  final int streak;
  final bool isPremium;
  const _BadgeRow({required this.xp, required this.streak, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Badges', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _badges.map((b) {
        final unlocked = _isUnlocked(b, xp, streak, isPremium);
        return AnimatedOpacity(
          opacity: unlocked ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.dawnAmber.withValues(alpha: 0.1) : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: unlocked ? AppTheme.dawnAmber.withValues(alpha: 0.4) : AppTheme.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(b.$1, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(b.$2, style: TextStyle(fontSize: 12, color: unlocked ? AppTheme.dawnAmber : AppTheme.textMuted, fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList()),
    ]);
  }

  bool _isUnlocked((String, String, int, int) badge, int xp, int streak, bool isPremium) {
    if (badge.$2 == 'Premium') return isPremium;
    if (badge.$4 > 0 && streak < badge.$4) return false;
    if (badge.$3 > 0 && xp < badge.$3) return false;
    return true;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Card(child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(height: 1, indent: 52, color: AppTheme.border),
        ],
      ])),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  const _InfoRow({required this.icon, required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        const Spacer(),
        Flexible(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: mono ? 'JetBrains Mono' : null), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
