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

// Palette constants
const _roseGold    = Color(0xFFE8A598);
const _lavender    = Color(0xFFA78BFA);
const _midnight    = Color(0xFF1B1836);
const _moonWhite   = Color(0xFFF8F6F2);

class ChatScreen extends StatefulWidget {
  final String coupleId;
  const ChatScreen({super.key, required this.coupleId});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _repo   = ChatRepository();
  final _scroll = ScrollController();
  final _uid    = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _typingTimer;
  bool _showQuick = false;

  // ── Partner ──────────────────────────────────────────────────────────────
  String _partnerName = 'Your Love';
  String _partnerUid  = '';
  DateTime? _partnerLastSeen;

  // ── Sleep Together ────────────────────────────────────────────────────────
  bool _myIsSleeping   = false;
  bool _isBothSleeping = false;

  // ── Atmosphere ────────────────────────────────────────────────────────────
  bool _isAnniversary = false;
  int? _anniversaryDays;
  MoodAura _moodAura  = MoodAura.none;

  // ── Subscriptions ─────────────────────────────────────────────────────────
  Timer? _presenceTimer;
  StreamSubscription? _moodSub, _presenceSub, _sleepSub;

  @override
  void initState() {
    super.initState();
    _loadCoupleData();
    _listenMood();
    _listenSleep();
    _startPresence();
    debugPrint('[ChatScreen] init coupleId=${widget.coupleId} uid=$_uid');
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadCoupleData() async {
    try {
      final doc  = await FirestoreService().coupleDoc(widget.coupleId).get();
      final data = doc.data() as Map<String, dynamic>?;

      final emails  = List<String>.from(data?['memberEmails'] ?? []);
      final members = List<String>.from(data?['members']      ?? []);
      final myEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      final partnerEmail = emails.firstWhere((e) => e != myEmail, orElse: () => '');
      final partnerUid   = members.firstWhere((m) => m != _uid,   orElse: () => '');
      final name         = _extractName(partnerEmail);

      final ann  = (data?['anniversaryDate'] as Timestamp?)?.toDate();
      final now  = DateTime.now();
      final isAnn = ann != null && ann.month == now.month && ann.day == now.day;

      if (mounted) setState(() {
        _partnerName    = name;
        _partnerUid     = partnerUid;
        _isAnniversary  = isAnn;
        _anniversaryDays = ann != null ? now.difference(ann).inDays : null;
      });

      if (partnerUid.isNotEmpty) _listenPresence(partnerUid);
    } catch (e) {
      debugPrint('[ChatScreen] loadCoupleData error: $e');
    }
  }

  String _extractName(String email) {
    if (email.isEmpty) return 'Your Love';
    final local = email.split('@')[0];
    return local.split(RegExp(r'[._]'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  void _startPresence() {
    _repo.updatePresence(widget.coupleId, _uid);
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) => _repo.updatePresence(widget.coupleId, _uid));
  }

  void _listenPresence(String partnerUid) {
    _presenceSub?.cancel();
    _presenceSub = _repo.partnerPresenceStream(widget.coupleId, partnerUid).listen((doc) {
      if (!mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      final ts   = data?['lastSeen'] as Timestamp?;
      setState(() => _partnerLastSeen = ts?.toDate());
    }, onError: (e) => debugPrint('[Chat] presence error: $e'));
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
          }, onError: (e) => debugPrint('[Chat] mood error: $e'));
    } catch (e) { debugPrint('[Chat] mood listen: $e'); }
  }

  void _listenSleep() {
    _sleepSub = _repo.sleepStream(widget.coupleId).listen((snap) {
      if (!mounted) return;
      final docs = snap.docs;
      bool my = false, both = false;
      try {
        final myDoc = docs.where((d) => d.id == _uid).firstOrNull;
        my = (myDoc?.data() as Map<String, dynamic>?)?['sleeping'] == true;
        both = docs.length >= 2 && docs.every((d) => (d.data() as Map<String, dynamic>)['sleeping'] == true);
      } catch (_) {}
      setState(() { _myIsSleeping = my; _isBothSleeping = both; });
    }, onError: (e) => debugPrint('[Chat] sleep error: $e'));
  }

  // ── Actions ────────────────────────────────────────────────────────────────

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
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  Future<void> _toggleSleep() async {
    final going = !_myIsSleeping;
    setState(() => _myIsSleeping = going);
    await _repo.setSleepMode(widget.coupleId, _uid, going);
    if (going) await _send('Good night 🌙');
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _presenceTimer?.cancel();
    _moodSub?.cancel();
    _presenceSub?.cancel();
    _sleepSub?.cancel();
    _repo.setTyping(widget.coupleId, _uid, false);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Glow color based on mood ──────────────────────────────────────────────

  Color get _glowColor => switch (_moodAura) {
    MoodAura.romantic   => _roseGold,
    MoodAura.missingYou => _lavender,
    MoodAura.excited    => const Color(0xFFF3C98B),
    _                   => _roseGold,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoveSkyBackground(
        moodOverride: _moodAura,
        isAnniversary: _isAnniversary,
        child: SafeArea(
          child: Column(children: [
            // ── App bar with partner name + live status ────────────────────
            _ChatHeader(
              partnerName: _partnerName,
              lastSeen: _partnerLastSeen,
              isSleeping: _myIsSleeping,
              onSleepTap: _toggleSleep,
            ),

            // ── Anniversary banner ─────────────────────────────────────────
            if (_isAnniversary && _anniversaryDays != null)
              _AnniversaryBanner(days: _anniversaryDays!),

            // ── Sleep mode overlay or message list ─────────────────────────
            Expanded(child: _isBothSleeping
              ? _SleepOverlay(onWake: _toggleSleep)
              : Stack(children: [
                  Positioned.fill(child: HeartbeatGlow(color: _glowColor)),
                  _MessageList(coupleId: widget.coupleId, uid: _uid, repo: _repo, scroll: _scroll),
                  // Typing indicator at bottom of list
                  Positioned(bottom: 8, left: 16, right: 16, child: _TypingIndicatorWrapper(
                    coupleId: widget.coupleId, uid: _uid, repo: _repo, partnerName: _partnerName,
                  )),
                ]),
            ),

            // ── Quick replies ──────────────────────────────────────────────
            if (_showQuick)
              _QuickReplies(replies: _quickReplies, onTap: (r) { _send(r); setState(() => _showQuick = false); }),

            // ── Input bar ──────────────────────────────────────────────────
            _InputBar(
              ctrl: _ctrl,
              onChanged: _onTextChanged,
              onSend: _send,
              onToggleQuick: () => setState(() => _showQuick = !_showQuick),
              showingQuick: _showQuick,
              isSleeping: _myIsSleeping,
              onSleepTap: _toggleSleep,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Chat Header with partner name + live heartbeat status ───────────────────

class _ChatHeader extends StatelessWidget {
  final String partnerName;
  final DateTime? lastSeen;
  final bool isSleeping;
  final VoidCallback onSleepTap;
  const _ChatHeader({required this.partnerName, required this.lastSeen, required this.isSleeping, required this.onSleepTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: _midnight.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: _roseGold.withValues(alpha: 0.12))),
      ),
      child: Row(children: [
        // Avatar
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_roseGold, _lavender]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _roseGold.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: Center(child: Text(
            partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '💕',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(partnerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _moonWhite)),
          const SizedBox(height: 2),
          _LiveHeartbeatStatus(lastSeen: lastSeen),
        ])),
        // Sleep toggle button
        GestureDetector(
          onTap: onSleepTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSleeping ? _lavender.withValues(alpha: 0.2) : _roseGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSleeping ? _lavender.withValues(alpha: 0.4) : _roseGold.withValues(alpha: 0.25)),
            ),
            child: Text(isSleeping ? '☀️' : '🌙', style: const TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

// ─── Live Heartbeat Status ────────────────────────────────────────────────────

class _LiveHeartbeatStatus extends StatefulWidget {
  final DateTime? lastSeen;
  const _LiveHeartbeatStatus({this.lastSeen});
  @override State<_LiveHeartbeatStatus> createState() => _LiveHeartbeatStatusState();
}

class _LiveHeartbeatStatusState extends State<_LiveHeartbeatStatus> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() {}); });
  }

  @override void dispose() { _pulse.dispose(); _refresh?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ls = widget.lastSeen;
    if (ls == null) {
      return const Text('💭  Missing you…', style: TextStyle(fontSize: 11, color: _lavender));
    }
    final diff = DateTime.now().difference(ls);
    if (diff.inSeconds < 120) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
          Text('💓', style: TextStyle(fontSize: 9 + _pulse.value * 2.0)),
          const SizedBox(width: 4),
          const Text('Heart beating…  Online now', style: TextStyle(fontSize: 11, color: Color(0xFF4ADE80))),
        ]),
      );
    }
    if (diff.inMinutes < 30) {
      final isNight = DateTime.now().hour >= 21 || DateTime.now().hour < 6;
      final label = diff.inMinutes < 1 ? 'just now' : '${diff.inMinutes}min ago';
      return Text(
        isNight ? '🌙  Dreaming…  Last seen $label' : '🌿  Away…  Last seen $label',
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      );
    }
    final label = diff.inHours >= 1 ? '${diff.inHours}h ago' : '${diff.inMinutes}min ago';
    return Text('💭  Missing you…  Inactive $label', style: const TextStyle(fontSize: 11, color: _lavender));
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
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_roseGold.withValues(alpha: 0.12), _lavender.withValues(alpha: 0.10)]),
        border: Border.symmetric(horizontal: BorderSide(color: _roseGold.withValues(alpha: 0.35))),
      ),
      child: Column(children: [
        const Text('🎉  Happy Anniversary! 🎉', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _roseGold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: _lavender)),
      ]),
    );
  }
}

// ─── Sleep Mode Overlay ───────────────────────────────────────────────────────

class _SleepOverlay extends StatelessWidget {
  final VoidCallback onWake;
  const _SleepOverlay({required this.onWake});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0818),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌙', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 24),
        const Text('Both sleeping ❤️', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _moonWhite)),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text('Your hearts are close even in dreams',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.6)),
        ),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: onWake,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _roseGold.withValues(alpha: 0.55)),
              color: _roseGold.withValues(alpha: 0.08),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('☀️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Good Morning', style: TextStyle(color: _roseGold, fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ])),
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
          return const Center(child: CircularProgressIndicator(color: _roseGold, strokeWidth: 2));
        }
        if (snap.hasError) {
          debugPrint('[Chat] message error: ${snap.error}');
          return Center(child: Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)));
        }
        final msgs = snap.data ?? [];
        if (msgs.isEmpty) return const _EmptyChat();
        return ListView.builder(
          controller: scroll,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final msg = msgs[i];
            final isMe = msg.senderId == uid;
            if (!isMe && msg.readAt == null) repo.markRead(coupleId, msg.id);
            return ChatBubble(content: msg.content, isMe: isMe, sentAt: msg.sentAt, readAt: msg.readAt, isQuickReply: msg.type == MessageType.quick);
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
    const Text('Your love story starts here', style: TextStyle(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w500)),
    const SizedBox(height: 6),
    Text('Messages are private — only the two of you', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 12)),
  ]));
}

// ─── Romantic Typing Indicator ────────────────────────────────────────────────

class _TypingIndicatorWrapper extends StatelessWidget {
  final String coupleId, uid, partnerName;
  final ChatRepository repo;
  const _TypingIndicatorWrapper({required this.coupleId, required this.uid, required this.repo, required this.partnerName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: repo.partnerTypingStream(coupleId, uid),
      builder: (_, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return _RomanticTypingIndicator(partnerName: partnerName);
      },
    );
  }
}

class _RomanticTypingIndicator extends StatefulWidget {
  final String partnerName;
  const _RomanticTypingIndicator({required this.partnerName});
  @override State<_RomanticTypingIndicator> createState() => _RomanticTypingIndicatorState();
}

class _RomanticTypingIndicatorState extends State<_RomanticTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _phraseIdx = 0;
  Timer? _phraseTimer;

  List<String> get _phrases => [
    '💭  ${widget.partnerName} is thinking about you…',
    '❤️  Writing something special…',
    '💌  Preparing a message…',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ctrl.forward();
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _phraseIdx = (_phraseIdx + 1) % _phrases.length);
        _ctrl.forward();
      });
    });
  }

  @override void dispose() { _ctrl.dispose(); _phraseTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _midnight.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _roseGold.withValues(alpha: 0.25)),
            boxShadow: [BoxShadow(color: _roseGold.withValues(alpha: 0.08), blurRadius: 10)],
          ),
          child: Text(_phrases[_phraseIdx], style: const TextStyle(fontSize: 12, color: _roseGold, fontStyle: FontStyle.italic)),
        ),
      ),
    );
  }
}

// ─── Quick Replies ────────────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.replies, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    color: _midnight.withValues(alpha: 0.9),
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
            color: _roseGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _roseGold.withValues(alpha: 0.35)),
          ),
          child: Center(child: Text(replies[i], style: const TextStyle(fontSize: 13, color: _roseGold))),
        ),
      ),
    ),
  );
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend, onToggleQuick, onSleepTap;
  final bool showingQuick, isSleeping;
  const _InputBar({required this.ctrl, required this.onChanged, required this.onSend, required this.onToggleQuick, required this.showingQuick, required this.isSleeping, required this.onSleepTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _midnight.withValues(alpha: 0.95),
      border: Border(top: BorderSide(color: _roseGold.withValues(alpha: 0.12))),
    ),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: SafeArea(top: false, child: Row(children: [
      IconButton(
        icon: Icon(showingQuick ? Icons.keyboard_arrow_down : Icons.flash_on, color: _roseGold, size: 20),
        onPressed: onToggleQuick,
      ),
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface2.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _roseGold.withValues(alpha: 0.18)),
        ),
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          maxLines: null,
          style: const TextStyle(color: _moonWhite, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Say something beautiful…',
            hintStyle: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_roseGold, Color(0xFFB8628E)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _roseGold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    ])),
  );
}
