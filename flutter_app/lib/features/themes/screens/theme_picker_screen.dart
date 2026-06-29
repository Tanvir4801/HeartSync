import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final td = provider.data;

    return Scaffold(
      appBar: AppBar(title: const Text('Romantic Theme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose your couple\'s theme',
            style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.5), letterSpacing: 0.04),
          ),
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
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? t.primary.withValues(alpha: 0.08) : t.background,
                  borderRadius: BorderRadius.circular(t.cardRadius),
                  border: Border.all(color: selected ? t.primary : t.border, width: selected ? 2 : 1.5),
                  boxShadow: selected ? [BoxShadow(color: t.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
                ),
                child: Row(children: [
                  _ThemePreview(theme: t),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(t.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.textOnSurface)),
                      if (selected) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      t.isLight ? 'Light · Claymorphism · Pastel' : 'Dark · Romantic',
                      style: TextStyle(fontSize: 11, color: t.textOnSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 8),
                    Row(children: t.heartColors.map((c) => Container(width: 14, height: 14, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: c, shape: BoxShape.circle))).toList()),
                  ])),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: td.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(td.cardRadius),
              border: Border.all(color: td.primary.withValues(alpha: 0.20)),
            ),
            child: Text(
              'Themes apply to the whole app instantly — backgrounds, cards, chat bubbles, and atmospheric effects all update together. Your partner sees their own theme choice independently.',
              style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55), height: 1.5),
            ),
          ),
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
        gradient: theme.isLight
            ? LinearGradient(colors: theme.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: theme.isLight ? null : theme.background,
        borderRadius: BorderRadius.circular(theme.cardRadius.clamp(0, 20)),
        border: Border.all(color: theme.border),
        boxShadow: theme.isLight ? [
          BoxShadow(color: theme.primary.withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 4)),
        ] : [],
      ),
      child: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 3, decoration: BoxDecoration(
          gradient: LinearGradient(colors: theme.heartColors),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(theme.cardRadius.clamp(0, 20)),
            bottomRight: Radius.circular(theme.cardRadius.clamp(0, 20)),
          ),
        ))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 32, height: 6, decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Container(width: 20, height: 12, decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(5))),
            const SizedBox(width: 4),
            Container(width: 20, height: 12, decoration: BoxDecoration(color: theme.secondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(5))),
          ]),
          const SizedBox(height: 4),
          Container(width: 40, height: 6, decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(3))),
        ])),
      ]),
    );
  }
}
