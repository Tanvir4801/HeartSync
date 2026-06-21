import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('AI Features ✨'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFE05C7E),
          labelColor: const Color(0xFFE05C7E),
          unselectedLabelColor: const Color(0xFF8888A8),
          tabs: const [Tab(text: 'Love Letter'), Tab(text: 'Caption'), Tab(text: 'Recap')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LoveLetterTab(coupleId: widget.coupleId),
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
        color: const Color(0xFF23232F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E3E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Generated', style: TextStyle(fontSize: 12, color: Color(0xFF8888A8))),
          const Spacer(),
          GestureDetector(
            onTap: () { Clipboard.setData(ClipboardData(text: text)); },
            child: const Icon(Icons.copy, size: 16, color: Color(0xFF8888A8)),
          ),
        ]),
        const Divider(color: Color(0xFF2E2E3E)),
        SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.7)),
      ]),
    );
  }
}

class _LoveLetterTab extends StatefulWidget {
  final String coupleId;
  const _LoveLetterTab({required this.coupleId});
  @override
  State<_LoveLetterTab> createState() => _LoveLetterTabState();
}

class _LoveLetterTabState extends State<_LoveLetterTab> {
  final _occasionCtrl = TextEditingController();
  String _tone = 'romantic';
  String? _result;
  bool _loading = false;
  final _repo = AiRepository();

  final _tones = ['romantic', 'playful', 'heartfelt', 'poetic', 'funny'];

  Future<void> _generate() async {
    if (_occasionCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = null; });
    try {
      final text = await _repo.generateLoveLetter(occasion: _occasionCtrl.text.trim(), tone: _tone, coupleId: widget.coupleId);
      setState(() => _result = text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF87171)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _occasionCtrl, decoration: const InputDecoration(labelText: 'Occasion', hintText: 'e.g. anniversary, missing you…')),
        const SizedBox(height: 16),
        const Text('Tone', style: TextStyle(fontSize: 13, color: Color(0xFF8888A8))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _tones.map((t) => ChoiceChip(
            label: Text(t, style: TextStyle(color: _tone == t ? const Color(0xFFE05C7E) : const Color(0xFF8888A8))),
            selected: _tone == t,
            onSelected: (_) => setState(() => _tone = t),
            backgroundColor: const Color(0xFF23232F),
            selectedColor: const Color(0xFFE05C7E).withOpacity(0.15),
            side: BorderSide(color: _tone == t ? const Color(0xFFE05C7E) : const Color(0xFF2E2E3E)),
          )).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✨'),
          label: Text(_loading ? 'Generating…' : 'Generate Love Letter'),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF87171)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Describe the memory (optional)', hintText: 'e.g. sunset photo from our Goa trip')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✨'),
          label: Text(_loading ? 'Generating…' : 'Suggest Captions'),
        )),
        if (_captions != null) ...List.generate(_captions!.length, (i) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E2E3E))),
          child: Text(_captions![i], style: const TextStyle(fontSize: 14, height: 1.5)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF87171)));
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
        Text('${_currentMonth()} Recap', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Generate an AI summary of this month\'s moments together.', style: TextStyle(color: Color(0xFF8888A8))),
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
