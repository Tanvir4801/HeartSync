import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme.dart';

class DreamBoardScreen extends StatefulWidget {
  final String coupleId;
  const DreamBoardScreen({super.key, required this.coupleId});
  @override
  State<DreamBoardScreen> createState() => _DreamBoardScreenState();
}

class _DreamBoardScreenState extends State<DreamBoardScreen> {
  String _selectedCategory = 'All';

  static const _categories = [
    ('All', '✨'), ('Travel', '✈️'), ('Home', '🏡'), ('Wedding', '💍'),
    ('Career', '🚀'), ('Life Goals', '🌟'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Board'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddSheet(context), tooltip: 'Add Dream'),
        ],
      ),
      body: Column(children: [
        _CategoryBar(categories: _categories, selected: _selectedCategory, onSelect: (c) => setState(() => _selectedCategory = c)),
        Expanded(child: _DreamGrid(coupleId: widget.coupleId, category: _selectedCategory)),
      ]),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddDreamSheet(coupleId: widget.coupleId, categories: _categories));
  }
}

class _CategoryBar extends StatelessWidget {
  final List<(String, String)> categories;
  final String selected;
  final Function(String) onSelect;
  const _CategoryBar({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final sel = c.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppTheme.dawnAmber.withValues(alpha: 0.15) : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppTheme.dawnAmber : AppTheme.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.$2, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(c.$1, style: TextStyle(fontSize: 12, color: sel ? AppTheme.dawnAmber : AppTheme.textMuted, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _DreamGrid extends StatelessWidget {
  final String coupleId, category;
  const _DreamGrid({required this.coupleId, required this.category});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('dreams').orderBy('createdAt', descending: true);
    if (category != 'All') query = query.where('category', isEqualTo: category);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _EmptyState(category: category);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _DreamCard(data: d, id: docs[i].id, coupleId: coupleId);
          },
        );
      },
    );
  }
}

class _DreamCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String id, coupleId;
  const _DreamCard({required this.data, required this.id, required this.coupleId});
  @override
  State<_DreamCard> createState() => _DreamCardState();
}

class _DreamCardState extends State<_DreamCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final completed = widget.data['completed'] as bool? ?? false;
    final categoryEmoji = _emoji(widget.data['category'] as String? ?? '');
    final colors = _colors(widget.data['category'] as String? ?? '');

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); _toggleComplete(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: completed ? [AppTheme.success.withValues(alpha: 0.15), AppTheme.success.withValues(alpha: 0.05)] : [colors[0].withValues(alpha: 0.12), colors[1].withValues(alpha: 0.06)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: completed ? AppTheme.success.withValues(alpha: 0.4) : colors[0].withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(categoryEmoji, style: const TextStyle(fontSize: 24)),
            if (completed) const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
          ]),
          const Spacer(),
          Text(widget.data['title'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, decoration: completed ? TextDecoration.lineThrough : null, color: completed ? AppTheme.textMuted : AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (widget.data['desc'] != null && (widget.data['desc'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.data['desc'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Text(widget.data['category'] as String? ?? '', style: TextStyle(fontSize: 10, color: colors[0], fontWeight: FontWeight.w600)),
        ]),
      )),
    );
  }

  void _toggleComplete() async {
    final current = widget.data['completed'] as bool? ?? false;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('dreams').doc(widget.id).update({'completed': !current});
  }

  String _emoji(String cat) {
    switch (cat) {
      case 'Travel': return '✈️';
      case 'Home': return '🏡';
      case 'Wedding': return '💍';
      case 'Career': return '🚀';
      case 'Life Goals': return '🌟';
      default: return '✨';
    }
  }

  List<Color> _colors(String cat) {
    switch (cat) {
      case 'Travel': return [AppTheme.lavenderDusk, AppTheme.duskIndigo];
      case 'Home': return [AppTheme.dawnAmber, AppTheme.horizonRose];
      case 'Wedding': return [AppTheme.horizonRose, AppTheme.lavenderDusk];
      case 'Career': return [const Color(0xFF56CFE1), AppTheme.lavenderDusk];
      default: return [AppTheme.dawnAmber, AppTheme.horizonRose];
    }
  }
}

class _AddDreamSheet extends StatefulWidget {
  final String coupleId;
  final List<(String, String)> categories;
  const _AddDreamSheet({required this.coupleId, required this.categories});
  @override
  State<_AddDreamSheet> createState() => _AddDreamSheetState();
}

class _AddDreamSheetState extends State<_AddDreamSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Travel';
  bool _saving = false;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('dreams').add({
      'title': _titleCtrl.text.trim(),
      'desc': _descCtrl.text.trim(),
      'category': _category,
      'completed': false,
      'addedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add a Dream', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Fraunces')),
        const SizedBox(height: 16),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Dream')),
        const SizedBox(height: 10),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: AppTheme.surface,
          decoration: const InputDecoration(labelText: 'Category'),
          items: widget.categories.where((c) => c.$1 != 'All').map((c) => DropdownMenuItem(value: c.$1, child: Text('${c.$2} ${c.$1}'))).toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 20),
        _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : ElevatedButton(onPressed: _save, child: const Text('Add to Dream Board ✨')),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('✨', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text(category == 'All' ? 'Your dream board is empty' : 'No $category dreams yet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Tap + to add your shared dreams and goals', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
    ]),
  ));
}
