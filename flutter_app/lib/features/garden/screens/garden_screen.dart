import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class GardenScreen extends StatefulWidget {
  final String coupleId;
  const GardenScreen({super.key, required this.coupleId});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> with TickerProviderStateMixin {
  int _memories = 0, _notes = 0, _streak = 0;
  late AnimationController _growCtrl;
  late Animation<double> _grow;

  @override
  void initState() {
    super.initState();
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.elasticOut);
    _loadStats();
  }

  void _loadStats() async {
    final coupleDoc = await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).get();
    final data = coupleDoc.data() ?? {};
    final memoriesSnap = await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('memories').get();
    final notesSnap = await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notes').get();
    setState(() {
      _memories = memoriesSnap.docs.length;
      _notes = notesSnap.docs.length;
      _streak = data['streak'] as int? ?? 0;
    });
    _growCtrl.forward();
  }

  @override
  void dispose() { _growCtrl.dispose(); super.dispose(); }

  int get _totalActivity => _memories + _notes + _streak;
  int get _plantLevel => (_totalActivity / 10).floor().clamp(0, 5);

  static const _plants = ['🌱', '🌿', '🌸', '🌺', '🌳', '🌲'];
  static const _plantNames = ['Seedling', 'Sprout', 'Blossom', 'Flower', 'Tree', 'Ancient Oak'];
  static const _plantDescs = [
    'Your love story is just beginning! 🌱',
    'You\'re growing stronger every day! 🌿',
    'Your love is starting to bloom! 🌸',
    'Beautiful! Your relationship is flourishing! 🌺',
    'Your love has grown into something magnificent! 🌳',
    'Legendary love! An ancient, unshakeable bond. 🌲',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relationship Garden')),
      body: Stack(children: [
        const FloatingHearts(count: 6, colors: [Color(0xFF4ADE80), AppTheme.dawnAmber, AppTheme.horizonRose]),
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _GardenDisplay(grow: _grow, level: _plantLevel, plants: _plants, names: _plantNames, descs: _plantDescs),
            const SizedBox(height: 24),
            _StatsRow(memories: _memories, notes: _notes, streak: _streak),
            const SizedBox(height: 24),
            _GardenActivities(coupleId: widget.coupleId),
            const SizedBox(height: 24),
            _Decorations(level: _plantLevel),
          ]),
        ),
      ]),
    );
  }
}

class _GardenDisplay extends StatelessWidget {
  final Animation<double> grow;
  final int level;
  final List<String> plants, names, descs;
  const _GardenDisplay({required this.grow, required this.level, required this.plants, required this.names, required this.descs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Container(height: 200, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            const Color(0xFF1A3A1A), const Color(0xFF2D5A1B),
          ]),
        ), child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            gradient: const LinearGradient(colors: [Color(0xFF3D2B1A), Color(0xFF5C3D1A)]),
          ))),
          Center(child: ScaleTransition(scale: grow, child: Text(plants[level], style: TextStyle(fontSize: 60 + level * 12.0)))),
          Positioned(bottom: 50, left: 20, child: Text(_randomFlowers(), style: const TextStyle(fontSize: 24))),
          Positioned(bottom: 50, right: 20, child: Text(_randomFlowers2(), style: const TextStyle(fontSize: 20))),
        ])),
        const SizedBox(height: 16),
        Text(names[level], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Fraunces', color: AppTheme.dawnAmber)),
        const SizedBox(height: 6),
        Text(descs[level], textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Level', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: HorizonLine(progress: (level + 1) / 6.0, colors: const [Color(0xFF4ADE80), AppTheme.dawnAmber])),
          const SizedBox(width: 8),
          Text('${level + 1}/6', style: const TextStyle(color: AppTheme.dawnAmber, fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'JetBrains Mono')),
        ]),
      ]),
    ));
  }

  String _randomFlowers() => ['🌼', '🌻', '🌷', '💐'][DateTime.now().day % 4];
  String _randomFlowers2() => ['🌸', '🌺', '🪻', '🌹'][DateTime.now().hour % 4];
}

class _StatsRow extends StatelessWidget {
  final int memories, notes, streak;
  const _StatsRow({required this.memories, required this.notes, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Stat(icon: '📸', label: 'Memories', value: memories, color: AppTheme.dawnAmber),
      const SizedBox(width: 10),
      _Stat(icon: '💌', label: 'Notes', value: notes, color: AppTheme.horizonRose),
      const SizedBox(width: 10),
      _Stat(icon: '🔥', label: 'Streak', value: streak, color: AppTheme.lavenderDusk),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String icon, label;
  final int value;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
    ]),
  )));
}

class _GardenActivities extends StatelessWidget {
  final String coupleId;
  const _GardenActivities({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('How to grow your garden', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...[
        ('📸', 'Add a memory', '+1 growth each'),
        ('💌', 'Send a love note', '+1 growth each'),
        ('🔥', 'Daily streak', '+1 per day active'),
        ('💬', 'Chat together', 'keeps garden healthy'),
        ('🤗', 'Send hugs', 'waters the garden'),
      ].map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: Row(children: [
            Text(a.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(a.$2, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            Text(a.$3, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]),
        ),
      )),
    ]);
  }
}

class _Decorations extends StatelessWidget {
  final int level;
  const _Decorations({required this.level});

  static const _items = [
    ('🪨', 'Stone Path', 0), ('💧', 'Fountain', 1), ('🦋', 'Butterfly', 2),
    ('🌈', 'Rainbow', 3), ('⭐', 'Star Lights', 4), ('🏡', 'Cottage', 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Garden Decorations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: _items.map((item) {
        final unlocked = level >= item.$3;
        return AnimatedOpacity(
          opacity: unlocked ? 1.0 : 0.35,
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: unlocked ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(item.$1, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(item.$2, style: TextStyle(fontSize: 12, color: unlocked ? AppTheme.success : AppTheme.textMuted)),
              if (!unlocked) ...[const SizedBox(width: 4), const Icon(Icons.lock_outline, size: 12, color: AppTheme.textMuted)],
            ]),
          ),
        );
      }).toList()),
    ]);
  }
}
