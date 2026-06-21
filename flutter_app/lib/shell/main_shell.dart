import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/home/screens/home_screen.dart';
import '../features/memories/screens/memory_timeline_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/gamification/screens/challenges_screen.dart';
import '../features/ai/screens/ai_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/milestones/screens/milestones_screen.dart';
import '../features/vault/screens/vault_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  final String coupleId;
  const MainShell({super.key, required this.coupleId});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  late final List<_NavItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      _NavItem(label: 'Home', icon: Icons.favorite_outline, activeIcon: Icons.favorite,
        builder: () => HomeScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Memories', icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library,
        builder: () => MemoryTimelineScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Chat', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,
        builder: () => ChatScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Notes', icon: Icons.mail_outline, activeIcon: Icons.mail,
        builder: () => NotesScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'More', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view,
        builder: () => _MoreScreen(coupleId: widget.coupleId)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _items.map((e) => e.builder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: _items.map((e) => NavigationDestination(
          icon: Icon(e.icon),
          selectedIcon: Icon(e.activeIcon),
          label: e.label,
        )).toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function() builder;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.builder});
}

class _MoreScreen extends StatelessWidget {
  final String coupleId;
  const _MoreScreen({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreCard(icon: Icons.auto_stories_outlined, title: 'Our Story', subtitle: 'Milestones, firsts, and special places', color: AppTheme.dawnAmber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MilestonesScreen(coupleId: coupleId)))),
          const SizedBox(height: 12),
          _MoreCard(icon: Icons.emoji_events_outlined, title: 'Challenges & XP', subtitle: 'Complete daily challenges together', color: AppTheme.warning,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChallengesScreen(coupleId: coupleId)))),
          const SizedBox(height: 12),
          _MoreCard(icon: Icons.auto_awesome_outlined, title: 'AI Features', subtitle: 'Love letters, captions & monthly recap', color: AppTheme.horizonRose,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiScreen(coupleId: coupleId)))),
          const SizedBox(height: 12),
          _MoreCard(icon: Icons.lock_outline, title: 'Love Vault', subtitle: 'PIN-protected private space', color: AppTheme.lavenderDusk,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()))),
          const SizedBox(height: 12),
          _MoreCard(icon: Icons.person_outline, title: 'Profile', subtitle: 'Account, couple info, stats', color: AppTheme.lavenderDusk,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(coupleId: coupleId)))),
          const SizedBox(height: 12),
          _MoreCard(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Preferences, support, privacy', color: AppTheme.textMuted,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MoreCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.25))),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
      ),
    );
  }
}
