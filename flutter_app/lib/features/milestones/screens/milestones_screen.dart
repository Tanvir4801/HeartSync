import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/milestone_model.dart';
import '../repository/milestone_repository.dart';
import '../../../core/theme.dart';

class MilestonesScreen extends StatelessWidget {
  final String coupleId;
  const MilestonesScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final repo = MilestoneRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Our Story')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.dawnAmber,
        onPressed: () => _showAddSheet(context, repo),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Milestone>>(
        stream: repo.milestonesStream(coupleId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber));
          final milestones = snap.data ?? [];
          if (milestones.isEmpty) return _EmptyState(onAdd: () => _showAddSheet(context, repo));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: milestones.length,
            itemBuilder: (_, i) {
              final m = milestones[i];
              return _MilestoneCard(milestone: m, coupleId: coupleId, repo: repo, isLast: i == milestones.length - 1);
            },
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, MilestoneRepository repo) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMilestoneSheet(coupleId: coupleId, repo: repo));
  }
}

class _MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final String coupleId;
  final MilestoneRepository repo;
  final bool isLast;
  const _MilestoneCard({required this.milestone, required this.coupleId, required this.repo, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.dawnAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dawnAmber.withValues(alpha: 0.4))),
            child: Center(child: Text(milestone.categoryIcon, style: const TextStyle(fontSize: 18)))),
          if (!isLast) Expanded(child: Container(width: 2, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 4))),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(milestone.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                GestureDetector(onTap: () => repo.deleteMilestone(coupleId, milestone.id), child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textMuted)),
              ]),
              if (milestone.description.isNotEmpty) ...[const SizedBox(height: 4), Text(milestone.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(DateFormat('MMMM d, yyyy').format(milestone.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'JetBrains Mono')),
                if (milestone.lat != null) ...[const SizedBox(width: 12), const Icon(Icons.location_on, size: 12, color: AppTheme.horizonRose), const SizedBox(width: 2), Text('${milestone.lat!.toStringAsFixed(2)}, ${milestone.lng!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppTheme.horizonRose, fontFamily: 'JetBrains Mono'))],
              ]),
            ]),
          )),
        )),
      ]),
    );
  }
}

class _AddMilestoneSheet extends StatefulWidget {
  final String coupleId;
  final MilestoneRepository repo;
  const _AddMilestoneSheet({required this.coupleId, required this.repo});
  @override
  State<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends State<_AddMilestoneSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  MilestoneCategory _category = MilestoneCategory.custom;
  bool _saving = false;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final m = Milestone(
      id: '', title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
      date: _date, category: _category,
      lat: _latCtrl.text.isNotEmpty ? double.tryParse(_latCtrl.text) : null,
      lng: _lngCtrl.text.isNotEmpty ? double.tryParse(_lngCtrl.text) : null,
    );
    await widget.repo.addMilestone(widget.coupleId, m);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Milestone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 10),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<MilestoneCategory>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          dropdownColor: AppTheme.surface,
          items: MilestoneCategory.values.map((c) => DropdownMenuItem(value: c, child: Text('${_icon(c)} ${c.name}'))).toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now(), builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!));
            if (d != null) setState(() => _date = d);
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: AppTheme.dawnAmber), const SizedBox(width: 8), Text(DateFormat('MMMM d, yyyy').format(_date), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13))])),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Lat (optional)'), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Lng (optional)'), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 20),
        _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : ElevatedButton(onPressed: _save, child: const Text('Add to Our Story')),
        const SizedBox(height: 20),
      ]),
    );
  }

  String _icon(MilestoneCategory c) {
    switch (c) {
      case MilestoneCategory.firstMeeting: return '💫';
      case MilestoneCategory.firstDate: return '🌹';
      case MilestoneCategory.trip: return '✈️';
      case MilestoneCategory.favorite: return '⭐';
      case MilestoneCategory.custom: return '📍';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('💫', style: TextStyle(fontSize: 60)),
    const SizedBox(height: 16),
    const Text('Your story starts here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Add milestones, firsts, and special places', style: TextStyle(color: AppTheme.textMuted)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: onAdd, child: const Text('Add First Milestone')),
  ]));
}
