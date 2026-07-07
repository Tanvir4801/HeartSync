import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _pulse = Tween(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ctrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final td = provider.data;
    final theme = AppTheme.availableThemes.single;

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        title: const Text('Romantic Theme'),
        backgroundColor: td.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      td.background,
                      td.primary.withValues(alpha: 0.05),
                      td.background,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Text(
                    'Only Sweetheart is available now. It is designed to stay soft, bright, and readable across the entire app.',
                    style: TextStyle(
                      fontSize: 13,
                      color: td.textOnSurface.withValues(alpha: 0.72),
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: GestureDetector(
                    onTap: () {
                      provider.setTheme(theme.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${theme.emoji} ${theme.name} theme applied!'),
                          backgroundColor: theme.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Transform.scale(
                        scale: _pulse.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.surface, theme.background],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(theme.cardRadius),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.24),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primary.withValues(alpha: 0.14),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _ThemePreview(theme: theme),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            theme.name,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: theme.textOnSurface,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: theme.primary.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: theme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Light · Claymorphism · Pastel',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.textOnSurface.withValues(alpha: 0.58),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: theme.heartColors
                                          .map(
                                            (c) => Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: c,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(theme.cardRadius),
                      border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      'Every screen now uses softer cards, warmer shadows, and clearer text contrast.',
                      style: TextStyle(
                        fontSize: 12,
                        color: td.textOnSurface.withValues(alpha: 0.74),
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(theme.cardRadius.clamp(0, 22)),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.heartColors),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(theme.cardRadius.clamp(0, 22)),
                  bottomRight: Radius.circular(theme.cardRadius.clamp(0, 22)),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.surface2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.secondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  width: 42,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
