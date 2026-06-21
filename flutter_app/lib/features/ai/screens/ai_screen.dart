import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../repository/ai_repository.dart';

class AiScreen extends StatefulWidget {
  final String coupleId;
  const AiScreen({super.key, required this.coupleId});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.dawnAmber,
          labelColor: AppTheme.dawnAmber,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [Tab(text: 'Generate'), Tab(text: 'Captions'), Tab(text: 'Recap')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _GenerateTab(coupleId: widget.coupleId),
          _CaptionTab(coupleId: widget.coupleId),
          _RecapTab(coupleId: widget.coupleId),
        ],
      ),
    );
  }
}

class _AiResultBox extends StatelessWidget {
  final String text;
  const _AiResultBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Generated', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const Spacer(),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Icon(Icons.copy, size: 16, color: AppTheme.textMuted),
          ),
        ]),
        const Divider(color: AppTheme.border),
        SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.7)),
      ]),
    );
  }
}

class _GenerateTab extends StatefulWidget {
  final String coupleId;
  const _GenerateTab({required this.coupleId});
  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  final _repo = AiRepository();
  String _type = 'love-letter';
  String _tone = 'romantic';
  final _contextCtrl = TextEditingController();
  String? _result;
  bool _loading = false;

  static const _types = [
    ('love-letter', 'Love Letter', '💌'),
    ('anniversary', 'Anniversary', '🎉'),
    ('birthday', 'Birthday', '🎂'),
    ('apology', 'Apology', '🙏'),
    ('poem', 'Poem', '📜'),
    ('good-morning', 'Good Morning', '🌅'),
    ('good-night', 'Good Night', '🌙'),
    ('miss-you', 'Miss You', '💭'),
  ];

  static const _tones = ['romantic', 'playful', 'sincere', 'poetic', 'warm', 'tender', 'heartfelt', 'funny'];

  Future<void> _generate() async {
    setState(() { _loading = true; _result = null; });
    try {
      final text = await _repo.generate(widget.coupleId, _type, _tone, _contextCtrl.text.trim().isEmpty ? null : _contextCtrl.text.trim());
      setState(() => _result = text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Type', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
          final sel = _type == t.$1;
          return GestureDetector(
            onTap: () => setState(() => _type = t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.dawnAmber.withValues(alpha: 0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppTheme.dawnAmber : AppTheme.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.$3, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(t.$2, style: TextStyle(fontSize: 12, color: sel ? AppTheme.dawnAmber : AppTheme.textMuted, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        const Text('Tone', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _tones.map((t) => ChoiceChip(
            label: Text(t, style: TextStyle(fontSize: 12, color: _tone == t ? AppTheme.horizonRose : AppTheme.textMuted)),
            selected: _tone == t,
            onSelected: (_) => setState(() => _tone = t),
            backgroundColor: AppTheme.surface,
            selectedColor: AppTheme.horizonRose.withValues(alpha: 0.12),
            side: BorderSide(color: _tone == t ? AppTheme.horizonRose : AppTheme.border),
          )).toList(),
        ),
        const SizedBox(height: 16),
        TextField(controller: _contextCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Context (optional)', hintText: 'e.g. our 2-year anniversary, you love sunsets...')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✨'),
          label: Text(_loading ? 'Generating…' : 'Generate'),
        )),
        if (_result != null) _AiResultBox(text: _result!),
      ]),
    );
  }
}

class _CaptionTab extends StatefulWidget {
  final String coupleId;
  const _CaptionTab({required this.coupleId});
  @override
  State<_CaptionTab> createState() => _CaptionTabState();
}

class _CaptionTabState extends State<_CaptionTab> {
  final _descCtrl = TextEditingController();
  List<String>? _captions;
  bool _loading = false;
  final _repo = AiRepository();

  Future<void> _generate() async {
    setState(() { _loading = true; _captions = null; });
    try {
      final caps = await _repo.generateCaptions(description: _descCtrl.text.trim(), coupleId: widget.coupleId);
      setState(() => _captions = caps);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Describe the memory (optional)', hintText: 'e.g. sunset photo from our Goa trip')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✨'),
          label: Text(_loading ? 'Generating…' : 'Suggest Captions'),
        )),
        if (_captions != null) ...List.generate(_captions!.length, (i) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: Row(children: [
            Text('${i + 1}.', style: const TextStyle(color: AppTheme.dawnAmber, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(child: Text(_captions![i], style: const TextStyle(fontSize: 14, height: 1.5))),
          ]),
        )),
      ]),
    );
  }
}

class _RecapTab extends StatefulWidget {
  final String coupleId;
  const _RecapTab({required this.coupleId});
  @override
  State<_RecapTab> createState() => _RecapTabState();
}

class _RecapTabState extends State<_RecapTab> {
  String? _recap;
  bool _loading = false;
  final _repo = AiRepository();

  Future<void> _generate() async {
    setState(() { _loading = true; _recap = null; });
    try {
      final rec = await _repo.generateMonthlyRecap(coupleId: widget.coupleId, month: _currentMonth());
      setState(() => _recap = rec);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _currentMonth() {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return months[DateTime.now().month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.lavenderDusk.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.lavenderDusk.withValues(alpha: 0.25))),
          child: const Text('This is an AI-generated reflection based on your activity. It is not an assessment of your relationship.', style: TextStyle(fontSize: 12, color: AppTheme.lavenderDusk, height: 1.5))),
        const SizedBox(height: 20),
        Text('${_currentMonth()} Recap', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Fraunces')),
        const SizedBox(height: 8),
        const Text('AI summary of this month\'s moments together.', style: TextStyle(color: AppTheme.textMuted)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✨'),
          label: Text(_loading ? 'Generating…' : 'Generate Monthly Recap'),
        )),
        if (_recap != null) _AiResultBox(text: _recap!),
      ]),
    );
  }
}
