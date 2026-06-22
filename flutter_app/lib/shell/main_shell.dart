import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/widgets/petal_bloom_route.dart';
import '../features/home/screens/home_screen.dart';
import '../features/garden/screens/garden_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/vault/screens/vault_screen.dart';
import '../features/themes/screens/theme_picker_screen.dart';

class MainShell extends StatefulWidget {
  final String coupleId;
  const MainShell({super.key, required this.coupleId});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _idx = 0;
  late AnimationController _navAnim;
  late final List<_NavItem> _items;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _items = [
      _NavItem(label: 'Home',   icon: Icons.favorite_outline,     activeIcon: Icons.favorite,      builder: () => HomeScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Garden', icon: Icons.nature_outlined,       activeIcon: Icons.nature,        builder: () => GardenScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Chat',   icon: Icons.chat_bubble_outline,   activeIcon: Icons.chat_bubble,   builder: () => ChatScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'Notes',  icon: Icons.mail_outline,          activeIcon: Icons.mail,          builder: () => NotesScreen(coupleId: widget.coupleId)),
      _NavItem(label: 'More',   icon: Icons.grid_view_outlined,    activeIcon: Icons.grid_view,     builder: () => _MoreScreen(coupleId: widget.coupleId)),
    ];
  }

  @override
  void dispose() { _navAnim.dispose(); super.dispose(); }

  void _onTap(int i) {
    setState(() => _idx = i);
    _navAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.watch<ThemeProvider>().data;
    return Scaffold(
      body: IndexedStack(index: _idx, children: _items.map((e) => e.builder()).toList()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: themeData.surface,
          border: Border(top: BorderSide(color: themeData.border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(children: List.generate(_items.length, (i) {
            final selected = _idx == i;
            return Expanded(child: GestureDetector(
              onTap: () => _onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedScale(
                    scale: selected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? _items[i].activeIcon : _items[i].icon,
                      size: 22,
                      color: selected ? themeData.primary : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_items[i].label, style: TextStyle(
                    fontSize: 10,
                    color: selected ? themeData.primary : AppTheme.textMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  )),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 20 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: selected ? LinearGradient(colors: [themeData.primary, themeData.secondary]) : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ]),
              ),
            ));
          })),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon, activeIcon;
  final Widget Function() builder;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.builder});
}

// ─── More Screen (account & utility only) ────────────────────────────────────

class _MoreScreen extends StatelessWidget {
  final String coupleId;
  const _MoreScreen({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final themeData = context.watch<ThemeProvider>().data;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('More', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
          Text('Account & settings', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w400)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('👤 Account'),
          _MoreCard(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Stats, badges & couple info',
            color: themeData.primary,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => ProfileScreen(coupleId: coupleId))),
          ),
          const SizedBox(height: 16),
          _sectionHeader('🎨 Appearance'),
          _MoreCard(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Change colors and mood',
            color: themeData.secondary,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => const ThemePickerScreen())),
          ),
          const SizedBox(height: 16),
          _sectionHeader('🔒 Private'),
          _MoreCard(
            icon: Icons.lock_outline,
            title: 'Love Vault',
            subtitle: 'PIN-protected private space',
            color: AppTheme.lavenderDusk,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => const VaultScreen())),
          ),
          const SizedBox(height: 16),
          _sectionHeader('⚙️ App'),
          _MoreCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Preferences, support & privacy',
            color: AppTheme.textMuted,
            onTap: () => Navigator.push(context, petalBloomRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4, left: 4),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.06)),
  );
}

class _MoreCard extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MoreCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  State<_MoreCard> createState() => _MoreCardState();
}

class _MoreCardState extends State<_MoreCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withValues(alpha: 0.25)),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(widget.subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ])),
            Icon(Icons.chevron_right, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 16),
          ]),
        ),
      ),
    );
  }
}
