import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../repository/chat_repository.dart';

const _quickReplies = ['Good morning ☀️', 'Good night 🌙', 'Miss you 💕', 'Love you ❤️', 'Thinking of you 💭'];

class ChatScreen extends StatefulWidget {
  final String coupleId;
  const ChatScreen({super.key, required this.coupleId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _repo = ChatRepository();
  final _scrollCtrl = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _typingTimer;
  bool _showQuickReplies = false;

  void _onTextChanged(String val) {
    _repo.setTyping(widget.coupleId, _uid, val.isNotEmpty);
    _typingTimer?.cancel();
    if (val.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 5), () => _repo.setTyping(widget.coupleId, _uid, false));
    }
  }

  Future<void> _send([String? text]) async {
    final content = text ?? _ctrl.text.trim();
    if (content.isEmpty) return;
    _ctrl.clear();
    _repo.setTyping(widget.coupleId, _uid, false);
    final msg = Message(
      id: '', senderId: _uid,
      type: text != null ? MessageType.quick : MessageType.text,
      content: content, sentAt: DateTime.now(),
    );
    await _repo.sendMessage(widget.coupleId, msg);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _repo.setTyping(widget.coupleId, _uid, false);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          StreamBuilder<bool>(
            stream: _repo.partnerTypingStream(widget.coupleId, _uid),
            builder: (_, snap) {
              if (snap.data == true) return const Padding(padding: EdgeInsets.only(right: 12), child: Text('typing…', style: TextStyle(fontSize: 12, color: Color(0xFF8888A8))));
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _repo.messagesStream(widget.coupleId),
            builder: (_, snap) {
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) return const Center(child: Text('Say hello! 👋', style: TextStyle(color: Color(0xFF8888A8))));
              return ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) => _Bubble(message: msgs[i], myUid: _uid, coupleId: widget.coupleId, repo: _repo),
              );
            },
          ),
        ),
        if (_showQuickReplies) _QuickReplies(replies: _quickReplies, onTap: (r) { _send(r); setState(() => _showQuickReplies = false); }),
        _InputBar(ctrl: _ctrl, onChanged: _onTextChanged, onSend: _send, onToggleQuick: () => setState(() => _showQuickReplies = !_showQuickReplies), showingQuick: _showQuickReplies),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final String myUid;
  final String coupleId;
  final ChatRepository repo;
  const _Bubble({required this.message, required this.myUid, required this.coupleId, required this.repo});

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == myUid;
    if (!isMe && message.readAt == null) repo.markRead(coupleId, message.id);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE05C7E) : const Color(0xFF23232F),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message.content, style: TextStyle(color: isMe ? Colors.white : const Color(0xFFF0F0F6), fontSize: 15)),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${message.sentAt.hour.toString().padLeft(2,'0')}:${message.sentAt.minute.toString().padLeft(2,'0')}',
                style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : const Color(0xFF8888A8))),
            if (isMe) ...[const SizedBox(width: 4), Icon(message.readAt != null ? Icons.done_all : Icons.done, size: 12, color: Colors.white60)],
          ]),
        ]),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, color: const Color(0xFF1A1A24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE05C7E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE05C7E).withOpacity(0.4)),
            ),
            child: Center(child: Text(replies[i], style: const TextStyle(fontSize: 13, color: Color(0xFFE05C7E)))),
          ),
        ),
      ),
    );
  }
}

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
      color: const Color(0xFF1A1A24),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(children: [
          IconButton(icon: Icon(showingQuick ? Icons.keyboard_arrow_down : Icons.flash_on, color: const Color(0xFFE05C7E)), onPressed: onToggleQuick),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Message…', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE05C7E), borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}
