import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge_model.dart';
import '../repository/gamification_repository.dart';

class ChallengesScreen extends StatelessWidget {
  final String coupleId;
  const ChallengesScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    final repo = GamificationRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    repo.initChallenges(coupleId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges & XP'),
        actions: [
          StreamBuilder<Map<String, dynamic>>(
            stream: repo.xpStream(coupleId),
            builder: (_, snap) {
              final xp = snap.data?['xp'] as int? ?? 0;
              final level = snap.data?['level'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Level $level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE05C7E))),
                  Text('$xp XP', style: const TextStyle(fontSize: 11, color: Color(0xFF8888A8))),
                ]),
              );
            },
          ),
        ],
      ),
      body: Column(children: [
        _DailyQuestion(repo: repo),
        Expanded(
          child: StreamBuilder<List<Challenge>>(
            stream: repo.challengesStream(coupleId),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE05C7E)));
              final challenges = snap.data ?? [];
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ChallengeCard(challenge: challenges[i], uid: uid, coupleId: coupleId, repo: repo),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DailyQuestion extends StatefulWidget {
  final GamificationRepository repo;
  const _DailyQuestion({required this.repo});
  @override
  State<_DailyQuestion> createState() => _DailyQuestionState();
}

class _DailyQuestionState extends State<_DailyQuestion> {
  String? _question;
  @override
  void initState() {
    super.initState();
    widget.repo.getDailyQuestion().then((q) => setState(() => _question = q));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFE05C7E).withOpacity(0.15), const Color(0xFFC04060).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE05C7E).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today\'s Question 💬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE05C7E))),
        const SizedBox(height: 8),
        Text(_question ?? 'Loading…', style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final String uid;
  final String coupleId;
  final GamificationRepository repo;
  const _ChallengeCard({required this.challenge, required this.uid, required this.coupleId, required this.repo});

  @override
  Widget build(BuildContext context) {
    final done = challenge.status == 'completed' || challenge.completedBy.contains(uid);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: done ? const Color(0xFF4ADE80).withOpacity(0.15) : const Color(0xFFE05C7E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(done ? Icons.check_circle : Icons.emoji_events_outlined,
                color: done ? const Color(0xFF4ADE80) : const Color(0xFFE05C7E), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(challenge.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: done ? const Color(0xFF8888A8) : const Color(0xFFF0F0F6), decoration: done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Text(challenge.description, style: const TextStyle(fontSize: 12, color: Color(0xFF8888A8))),
          ])),
          const SizedBox(width: 8),
          Column(children: [
            Text('+${challenge.xpReward}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE05C7E))),
            const Text('XP', style: TextStyle(fontSize: 10, color: Color(0xFF8888A8))),
          ]),
          const SizedBox(width: 8),
          if (!done) IconButton(
            icon: const Icon(Icons.done, color: Color(0xFF4ADE80)),
            onPressed: () => repo.completeChallenge(coupleId, challenge.id, uid, challenge.xpReward),
          ),
        ]),
      ),
    );
  }
}
