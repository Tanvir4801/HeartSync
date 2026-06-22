import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Romantic Theme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Choose your couple\'s theme', style: TextStyle(fontSize: 13, color: AppTheme.textMuted, letterSpacing: 0.04)),
          const SizedBox(height: 16),
          ...AppTheme.themes.entries.map((entry) {
            final t = entry.value;
            final selected = provider.current == t.id;
            return GestureDetector(
              onTap: () {
                provider.setTheme(t.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${t.emoji} ${t.name} theme applied!'),
                  backgroundColor: t.primary,
                  duration: const Duration(seconds: 2),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? t.primary.withValues(alpha: 0.08) : t.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? t.primary : t.border, width: selected ? 2 : 1.5),
                  boxShadow: selected ? [BoxShadow(color: t.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))] : [],
                ),
                child: Row(children: [
                  _ThemePreview(theme: t),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(t.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      if (selected) ...[const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(8)), child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)))],
                    ]),
                    const SizedBox(height: 6),
                    Row(children: t.heartColors.map((c) => Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: c, shape: BoxShape.circle))).toList()),
                  ])),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.lavenderDusk.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.lavenderDusk.withValues(alpha: 0.25))),
            child: const Text('Themes apply to the whole app instantly. Your partner sees their own theme choice independently.', style: TextStyle(fontSize: 12, color: AppTheme.lavenderDusk, height: 1.5))),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final HeartSyncThemeData theme;
  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 3, decoration: BoxDecoration(
          gradient: LinearGradient(colors: theme.gradient.isEmpty ? [theme.primary, theme.secondary] : theme.heartColors),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        ))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 32, height: 6, decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Container(width: 20, height: 12, decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 4),
            Container(width: 20, height: 12, decoration: BoxDecoration(color: theme.secondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          ]),
          const SizedBox(height: 4),
          Container(width: 40, height: 6, decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(3))),
        ])),
      ]),
    );
  }
}
