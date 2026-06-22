import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme.dart';

class ConnectScreen extends StatefulWidget {
  final String coupleId;
  const ConnectScreen({super.key, required this.coupleId});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppTheme.dawnAmber,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.dawnAmber,
          tabs: const [Tab(text: '🎲 Fun'), Tab(text: '💭 Deep Talks'), Tab(text: '🔮 Future'), Tab(text: '🏆 Quiz')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _QuestionTab(coupleId: widget.coupleId, category: 'fun'),
        _QuestionTab(coupleId: widget.coupleId, category: 'deep'),
        _QuestionTab(coupleId: widget.coupleId, category: 'future'),
        _QuizTab(coupleId: widget.coupleId),
      ]),
    );
  }
}

final _funQuestions = [
  'Never have I ever… stayed up past 3am talking to you 🌙',
  'This or that: Morning coffee ☕ or Evening tea 🍵?',
  'Agree or disagree: Pineapple belongs on pizza 🍕',
  'Never have I ever… cried at a movie we watched together 🎬',
  'This or that: Beach holiday 🏖️ or Mountain retreat 🏔️?',
  'Agree or disagree: The best dates are spontaneous ones ✨',
  'Never have I ever… sent you a voice note while half asleep 😴',
  'This or that: Cook together 🍳 or Order takeout? 🥡',
];

final _deepQuestions = [
  'What\'s one thing you wish I understood better about you? 💭',
  'When do you feel most loved by me? 💛',
  'What dream of yours do you think about the most? 🌟',
  'What\'s something you\'ve never told me but want to? 🤫',
  'How do you want to feel in this relationship 5 years from now? 🔮',
  'What\'s one thing I do that makes you feel truly seen? 👁️',
  'What does home feel like to you? 🏡',
];

final _futureQuestions = [
  'Where would you want us to travel first? ✈️',
  'Describe our ideal home together 🏡',
  'What tradition do you want us to start? 🎄',
  'What\'s a skill you want us to learn together? 📚',
  'How do you imagine our mornings in 10 years? ☀️',
  'What\'s one place you\'d love us to live someday? 🌍',
];

class _QuestionTab extends StatefulWidget {
  final String coupleId, category;
  const _QuestionTab({required this.coupleId, required this.category});
  @override
  State<_QuestionTab> createState() => _QuestionTabState();
}

class _QuestionTabState extends State<_QuestionTab> {
  int _currentIndex = 0;
  final _answerCtrl = TextEditingController();
  bool _answered = false;
  bool _saving = false;
  late List<String> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.category == 'fun' ? _funQuestions : widget.category == 'deep' ? _deepQuestions : _futureQuestions;
    _currentIndex = DateTime.now().day % _questions.length;
  }

  Future<void> _saveAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('connect_answers').add({
      'question': _questions[_currentIndex],
      'answer': _answerCtrl.text.trim(),
      'from': uid,
      'category': widget.category,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() { _saving = false; _answered = true; });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _questions.length;
      _answered = false;
      _answerCtrl.clear();
    });
  }

  @override
  void dispose() { _answerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _QuestionCard(question: _questions[_currentIndex], answered: _answered),
      const SizedBox(height: 20),
      if (!_answered) ...[
        TextField(controller: _answerCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Your answer…', alignLabelWithHint: true)),
        const SizedBox(height: 14),
        _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.dawnAmber)) : GlowButton(label: 'Share Answer 💛', icon: Icons.send_rounded, onTap: _saveAnswer),
      ] else ...[
        GlassCard(child: Column(children: [
          const Text('✅', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text('Answer saved!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Your partner will see it when they open the app', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton(onPressed: _next, child: const Text('Next Question →')),
        ])),
      ],
      const SizedBox(height: 24),
      _PastAnswers(coupleId: widget.coupleId, category: widget.category),
    ]);
  }
}

class _QuestionCard extends StatefulWidget {
  final String question;
  final bool answered;
  const _QuestionCard({required this.question, required this.answered});
  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _QuestionCard old) {
    super.didUpdateWidget(old);
    if (old.question != widget.question) { _ctrl.reset(); _ctrl.forward(); }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.duskIndigo, Color(0xFF2A2448)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dawnAmber.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppTheme.dawnAmber.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💬', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          const Text("Today's Prompt", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        Text(widget.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.5, fontFamily: 'Fraunces')),
      ]),
    ));
  }
}

class _PastAnswers extends StatelessWidget {
  final String coupleId, category;
  const _PastAnswers({required this.coupleId, required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('connect_answers').where('category', isEqualTo: category).orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Past Answers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['question'] as String? ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Text('"${data['answer'] as String? ?? ''}"', style: const TextStyle(fontSize: 13, height: 1.5)),
              ]));
          }),
        ]);
      },
    );
  }
}

class _QuizTab extends StatefulWidget {
  final String coupleId;
  const _QuizTab({required this.coupleId});
  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  int _questionIndex = 0;
  int _score = 0;
  bool _done = false;
  bool _showConfetti = false;
  String? _selected;

  static const _questions = [
    _QuizQuestion("What's my love language?", ["Words of Affirmation", "Physical Touch", "Quality Time", "Acts of Service", "Gifts"], null),
    _QuizQuestion("What's my dream vacation?", ["Paris 🇫🇷", "Maldives 🏝️", "Tokyo 🇯🇵", "New York 🗽"], null),
    _QuizQuestion("My favourite time of day with you is?", ["Morning cuddles ☀️", "Evening walks 🌙", "Lunch together 🍜", "Late night talks 🌟"], null),
    _QuizQuestion("What song reminds me of us?", ["Our actual song 🎵", "Any love song 🎶", "A sad one sometimes 😔", "Background music 🎧"], null),
    _QuizQuestion("What's one thing I can't live without?", ["Coffee ☕", "Music 🎵", "Your messages 💌", "Food 🍕"], null),
  ];

  void _answer(String answer) {
    setState(() => _selected = answer);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _score++;
        _selected = null;
        if (_questionIndex < _questions.length - 1) {
          _questionIndex++;
        } else {
          _done = true;
          _showConfetti = true;
          Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showConfetti = false); });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: _done ? _DoneCard(score: _score, total: _questions.length, onRestart: () => setState(() { _questionIndex = 0; _score = 0; _done = false; })) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Q${_questionIndex + 1}/${_questions.length}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'JetBrains Mono')),
            const SizedBox(width: 12),
            Expanded(child: HorizonLine(progress: (_questionIndex + 1) / _questions.length)),
          ]),
          const SizedBox(height: 24),
          _QuestionCard(question: _questions[_questionIndex].question, answered: false),
          const SizedBox(height: 20),
          ..._questions[_questionIndex].options.map((opt) {
            final isSel = _selected == opt;
            return GestureDetector(
              onTap: () => _answer(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.dawnAmber.withValues(alpha: 0.15) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSel ? AppTheme.dawnAmber : AppTheme.border, width: isSel ? 2 : 1),
                ),
                child: Text(opt, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? AppTheme.dawnAmber : AppTheme.textPrimary)),
              ),
            );
          }),
        ]),
      ),
      if (_showConfetti) const ConfettiOverlay(),
    ]);
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final String? correctAnswer;
  const _QuizQuestion(this.question, this.options, this.correctAnswer);
}

class _DoneCard extends StatelessWidget {
  final int score, total;
  final VoidCallback onRestart;
  const _DoneCard({required this.score, required this.total, required this.onRestart});

  @override
  Widget build(BuildContext context) => Center(child: GlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const HeartbeatPulse(child: Text('🏆', style: TextStyle(fontSize: 56))),
    const SizedBox(height: 16),
    const Text('Quiz Complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
    const SizedBox(height: 8),
    Text('You scored $score/$total', style: const TextStyle(fontSize: 16, color: AppTheme.dawnAmber, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Share your answers and compare with your partner!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: onRestart, child: const Text('Play Again')),
  ])));
}
