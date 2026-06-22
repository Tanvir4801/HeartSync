import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../core/firestore_service.dart';
import '../../../core/widgets/love_sky.dart';
import '../models/message_model.dart';
import '../repository/chat_repository.dart';
import '../widgets/chat_bubble.dart';

const _quickReplies = ['Good morning ☀️', 'Good night 🌙', 'Miss you 💕', 'Love you ❤️', 'Thinking of you 💭'];

class ChatScreen extends StatefulWidget {
  final String coupleId;
  const ChatScreen({super.key, required this.coupleId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl    = TextEditingController();
  final _repo    = ChatRepository();
  final _scroll  = ScrollController();
  final _uid     = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _typingTimer;
  bool _showQuick = false;

  // ── Atmosphere ──────────────────────────────────────────────────────────────
  bool _isAnniversary = false;
  int? _daysTogetherOnAnniversary;
  MoodAura _moodAura = MoodAura.none;
  StreamSubscription? _moodSub;

  @override
  void initState() {
    super.initState();
    _checkAnniversary();
    _listenMood();
    debugPrint('[ChatScreen] init — coupleId=${widget.coupleId} uid=$_uid');
  }

  Future<void> _checkAnniversary() async {
    try {
      final doc = await FirestoreService().coupleDoc(widget.coupleId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final ann = (data?['anniversaryDate'] as Timestamp?)?.toDate();
      if (ann == null || !mounted) return;
      final now = DateTime.now();
      final isAnn = ann.month == now.month && ann.day == now.day;
      final days  = now.difference(ann).inDays;
      setState(() { _isAnniversary = isAnn; _daysTogetherOnAnniversary = days; });
    } catch (e) {
      debugPrint('[ChatScreen] anniversary check error: $e');
    }
  }

  void _listenMood() {
    try {
      _moodSub = FirestoreService()
          .sub(widget.coupleId, 'moods')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snap) {
            if (!mounted || snap.docs.isEmpty) return;
            final data  = snap.docs.first.data() as Map<String, dynamic>;
            final emoji = data['mood'] as String?;
            final aura  = emojiToAura(emoji);
            if (aura != _moodAura) setState(() => _moodAura = aura);
          }, onError: (e) => debugPrint('[ChatScreen] mood stream error: $e'));
    } catch (e) {
      debugPrint('[ChatScreen] mood listen error: $e');
    }
  }

  void _onTextChanged(String val) {
    _repo.setTyping(widget.coupleId, _uid, val.isNotEmpty);
    _typingTimer?.cancel();
    if (val.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 5), () => _repo.setTyping(widget.coupleId, _uid, false));
    }
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _repo.setTyping(widget.coupleId, _uid, false);
    await _repo.sendMessage(widget.coupleId, Message(
      id: '', senderId: _uid,
      type: preset != null ? MessageType.quick : MessageType.text,
      content: text, sentAt: DateTime.now(),
    ));
    try { await FirestoreService().updateDailyAction(widget.coupleId, _uid); } catch (_) {}
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _moodSub?.cancel();
    _repo.setTyping(widget.coupleId, _uid, false);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Aura color for heartbeat glow — changes with mood
  Color get _glowColor {
    return switch (_moodAura) {
      MoodAura.romantic   => const Color(0xFFE8A598),
      MoodAura.missingYou => const Color(0xFFA78BFA),
      MoodAura.excited    => const Color(0xFFF3C98B),
      MoodAura.happy      => const Color(0xFFE8A598),
      MoodAura.none       => const Color(0xFFE8A598),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoveSkyBackground(
        moodOverride: _moodAura,
        isAnniversary: _isAnniversary,
        child: SafeArea(
          child: Column(children: [
            _AppBar(coupleId: widget.coupleId, uid: _uid, repo: _repo),

            // Anniversary banner (golden, once a year)
            if (_isAnniversary && _daysTogetherOnAnniversary != null)
              _AnniversaryBanner(days: _daysTogetherOnAnniversary!),

            // Message list + heartbeat glow
            Expanded(child: Stack(children: [
              Positioned.fill(child: HeartbeatGlow(color: _glowColor)),
              _MessageList(coupleId: widget.coupleId, uid: _uid, repo: _repo, scroll: _scroll),
            ])),

            // Quick replies
            if (_showQuick)
              _QuickReplies(replies: _quickReplies, onTap: (r) { _send(r); setState(() => _showQuick = false); }),

            // Input bar
            _InputBar(
              ctrl: _ctrl,
              onChanged: _onTextChanged,
              onSend: _send,
              onToggleQuick: () => setState(() => _showQuick = !_showQuick),
              showingQuick: _showQuick,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String coupleId, uid;
  final ChatRepository repo;
  const _AppBar({required this.coupleId, required this.uid, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        const Text('💬', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text('Private • End-to-End', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        StreamBuilder<bool>(
          stream: repo.partnerTypingStream(coupleId, uid),
          builder: (_, snap) {
            if (snap.data != true) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8A598).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8A598).withValues(alpha: 0.3)),
              ),
              child: const Text('typing…', style: TextStyle(fontSize: 11, color: Color(0xFFE8A598))),
            );
          },
        ),
      ]),
    );
  }
}

// ─── Anniversary Banner ───────────────────────────────────────────────────────

class _AnniversaryBanner extends StatelessWidget {
  final int days;
  const _AnniversaryBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    final years = days ~/ 365;
    final label = years >= 1 ? '$years year${years == 1 ? '' : 's'} together' : '$days days together';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFF3C98B).withValues(alpha: 0.15),
          const Color(0xFFE8A598).withValues(alpha: 0.15),
        ]),
        border: Border.symmetric(horizontal: BorderSide(color: const Color(0xFFF3C98B).withValues(alpha: 0.4))),
      ),
      child: Column(children: [
        const Text('🎉 Happy Anniversary! 🎉', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF3C98B))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFE8A598))),
      ]),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final String coupleId, uid;
  final ChatRepository repo;
  final ScrollController scroll;
  const _MessageList({required this.coupleId, required this.uid, required this.repo, required this.scroll});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
      stream: repo.messagesStream(coupleId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8A598), strokeWidth: 2));
        }
        if (snap.hasError) {
          debugPrint('[Chat] message stream error: ${snap.error}');
          return Center(child: Text('Chat unavailable\n${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)));
        }
        final msgs = snap.data ?? [];
        if (msgs.isEmpty) return const _EmptyChat();
        return ListView.builder(
          controller: scroll,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final msg = msgs[i];
            final isMe = msg.senderId == uid;
            if (!isMe && msg.readAt == null) repo.markRead(coupleId, msg.id);
            return ChatBubble(
              content: msg.content,
              isMe: isMe,
              sentAt: msg.sentAt,
              readAt: msg.readAt,
              isQuickReply: msg.type == MessageType.quick,
            );
          },
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('💕', style: TextStyle(fontSize: 56)),
    const SizedBox(height: 14),
    const Text('Say hello!', style: TextStyle(color: AppTheme.textMuted, fontSize: 17, fontWeight: FontWeight.w500)),
    const SizedBox(height: 6),
    const Text('Your conversation is private and\nonly visible to the two of you.',
      textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
  ]));
}

// ─── Quick Replies ────────────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: const Color(0xFF1B1836).withValues(alpha: 0.9),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A598).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8A598).withValues(alpha: 0.35)),
            ),
            child: Center(child: Text(replies[i], style: const TextStyle(fontSize: 13, color: Color(0xFFE8A598)))),
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onToggleQuick;
  final bool showingQuick;
  const _InputBar({required this.ctrl, required this.onChanged, required this.onSend, required this.onToggleQuick, required this.showingQuick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1836).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: const Color(0xFFE8A598).withValues(alpha: 0.15))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(top: false, child: Row(children: [
        IconButton(
          icon: Icon(showingQuick ? Icons.keyboard_arrow_down : Icons.flash_on,
            color: const Color(0xFFE8A598), size: 20),
          onPressed: onToggleQuick,
        ),
        Expanded(child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface2.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8A598).withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            maxLines: null,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Message…',
              hintStyle: TextStyle(color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE8A598), Color(0xFFD47B8E)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33E8A598), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ])),
    );
  }
}
