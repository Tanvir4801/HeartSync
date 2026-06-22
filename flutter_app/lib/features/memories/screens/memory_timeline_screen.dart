import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../models/memory_model.dart';
import '../repository/memory_repository.dart';
import 'add_memory_screen.dart';

class MemoryTimelineScreen extends StatelessWidget {
  final String coupleId;
  const MemoryTimelineScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final repo = MemoryRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Memories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
          Text('Your shared moments', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))),
          ),
        ],
      ),
      body: StreamBuilder<List<Memory>>(
        stream: repo.memoriesStream(coupleId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)));
          }
          if (snap.hasError) {
            final errStr = snap.error.toString();
            return _ErrorState(
              hint: errStr.contains('index')
                  ? 'A Firestore index is missing. Open Firebase Console > Firestore > Indexes to create it.'
                  : errStr.contains('permission')
                      ? 'Permission denied — check your Firestore security rules.'
                      : errStr,
            );
          }
          final memories = snap.data ?? [];
          if (memories.isEmpty) return _EmptyState(coupleId: coupleId);

          final grouped = <String, List<Memory>>{};
          for (final m in memories) {
            final key = DateFormat('MMMM yyyy').format(m.date);
            grouped.putIfAbsent(key, () => []).add(m);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...grouped.entries.map((e) => _MonthSection(month: e.key, memories: e.value, coupleId: coupleId, repo: repo)),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String hint;
  const _ErrorState({required this.hint});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
        const SizedBox(height: 16),
        const Text('Could not load memories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
      ]),
    ),
  );
}

class _MonthSection extends StatelessWidget {
  final String month;
  final List<Memory> memories;
  final String coupleId;
  final MemoryRepository repo;
  const _MonthSection({required this.month, required this.memories, required this.coupleId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(month, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: memories.length,
        itemBuilder: (_, i) => _MemoryCard(memory: memories[i], coupleId: coupleId, repo: repo),
      ),
    ]);
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final String coupleId;
  final MemoryRepository repo;
  const _MemoryCard({required this.memory, required this.coupleId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(fit: StackFit.expand, children: [
          memory.url.isNotEmpty
              ? Image.network(memory.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.surface2, child: Icon(Icons.broken_image, color: AppTheme.textMuted)))
              : const ColoredBox(color: AppTheme.surface2, child: Icon(Icons.image, color: AppTheme.textMuted)),
          if (memory.caption.isNotEmpty)
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)])),
              child: Text(memory.caption, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
            )),
          if (memory.isFavorite) const Positioned(top: 8, right: 8, child: Icon(Icons.favorite, color: Color(0xFFE05C7E), size: 16)),
        ]),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (memory.url.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(memory.url, fit: BoxFit.contain)),
        if (memory.caption.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(memory.caption, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: Icon(memory.isFavorite ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFE05C7E)),
            onPressed: () { repo.toggleFavorite(coupleId, memory.id, memory.isFavorite); Navigator.pop(context); },
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ]),
      ]),
    ));
  }
}

class _EmptyState extends StatelessWidget {
  final String coupleId;
  const _EmptyState({required this.coupleId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📸', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        const Text('No memories yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Fraunces')),
        const SizedBox(height: 10),
        const Text('Start capturing your moments together', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add Memory'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId))),
        ),
      ]),
    ));
  }
}
