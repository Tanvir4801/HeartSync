import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(title: const Text('Memories'), actions: [
        IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId)))),
      ]),
      body: StreamBuilder<List<Memory>>(
        stream: repo.memoriesStream(coupleId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)));
          final memories = snap.data ?? [];
          if (memories.isEmpty) return _EmptyState(coupleId: coupleId);
          final grouped = <String, List<Memory>>{};
          for (final m in memories) {
            final key = DateFormat('MMMM yyyy').format(m.date);
            grouped.putIfAbsent(key, () => []).add(m);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((e) => _MonthSection(month: e.key, memories: e.value, coupleId: coupleId, repo: repo)).toList(),
          );
        },
      ),
    );
  }
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
        child: Text(month, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8888A8), letterSpacing: 0.5)),
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
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          memory.url.isNotEmpty
              ? Image.network(memory.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF23232F), child: Icon(Icons.broken_image, color: Color(0xFF8888A8))))
              : const ColoredBox(color: Color(0xFF23232F), child: Icon(Icons.image, color: Color(0xFF8888A8))),
          Positioned(bottom: 0, left: 0, right: 0, child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (memory.url.isNotEmpty) Image.network(memory.url, fit: BoxFit.contain),
        if (memory.caption.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(memory.caption, style: const TextStyle(color: Colors.white))),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📸', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      const Text('No memories yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Start capturing your moments together', style: TextStyle(color: Color(0xFF8888A8))),
      const SizedBox(height: 24),
      ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Add Memory'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemoryScreen(coupleId: coupleId)))),
    ]));
  }
}
