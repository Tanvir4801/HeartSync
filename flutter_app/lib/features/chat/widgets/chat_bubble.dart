import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

// Dark theme palette constants
const _roseGold  = Color(0xFFE8A598);
const _lavender  = Color(0xFFA78BFA);
const _midnight  = Color(0xFF1B1836);
const _moonWhite = Color(0xFFF8F6F2);

bool isSpecialMessage(String content) {
  final lower = content.toLowerCase();
  return lower.contains('i love you') ||
      lower.contains('i miss you') ||
      lower.contains('love you so');
}

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isQuickReply;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.sentAt,
    this.readAt,
    this.isQuickReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final special = isSpecialMessage(content);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if (special)
          _SpecialBubble(content: content, isMe: isMe, td: td)
        else if (isMe)
          _SentBubble(content: content, isQuickReply: isQuickReply, td: td)
        else
          _ReceivedBubble(content: content, td: td),

        const SizedBox(height: 3),
        Padding(
          padding: EdgeInsets.only(left: isMe ? 0 : 14, right: isMe ? 14 : 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: td.isLight ? td.textOnSurface.withValues(alpha: 0.4) : AppTheme.textMuted),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(readAt != null ? Icons.done_all : Icons.done, size: 12,
                color: readAt != null ? AppTheme.success : (td.isLight ? td.textOnSurface.withValues(alpha: 0.35) : AppTheme.textMuted)),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Received Bubble ──────────────────────────────────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final String content;
  final HeartSyncThemeData td;
  const _ReceivedBubble({required this.content, required this.td});

  @override
  Widget build(BuildContext context) {
    if (td.isLight) {
      // Sweetheart: claymorphism chip — Cloud White with lavender puffy shadow
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
          child: Container(
            margin: const EdgeInsets.only(right: 60),
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: td.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22), topRight: Radius.circular(22),
                bottomRight: Radius.circular(22), bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: td.border),
              boxShadow: [
                BoxShadow(color: td.primary.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 5)),
              ],
            ),
            child: Text(content, style: TextStyle(color: td.textOnSurface, fontSize: 15, height: 1.45)),
          ),
        ),
      );
    }

    // Dark: glassmorphism frosted glass (original)
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
        child: Container(
          margin: const EdgeInsets.only(right: 60),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: _moonWhite.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomRight: Radius.circular(20), bottomLeft: Radius.circular(5),
            ),
            border: Border.all(color: _lavender.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(color: _lavender.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(content, style: const TextStyle(color: _moonWhite, fontSize: 15, height: 1.45)),
        ),
      ),
    );
  }
}

// ─── Sent Bubble ──────────────────────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final String content;
  final bool isQuickReply;
  final HeartSyncThemeData td;
  const _SentBubble({required this.content, required this.isQuickReply, required this.td});

  @override
  Widget build(BuildContext context) {
    if (td.isLight) {
      // Sweetheart: claymorphism chip with primary gradient
      final colors = isQuickReply
          ? [td.secondary, td.secondary.withValues(alpha: 0.7)]
          : [td.primary, td.primary.withValues(alpha: 0.75)];
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
          child: Container(
            margin: const EdgeInsets.only(left: 60),
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22), topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22), bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(color: colors.first.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: 1),
              ],
            ),
            child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45)),
          ),
        ),
      );
    }

    // Dark: rose gold gradient with glow (original)
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
        child: Container(
          margin: const EdgeInsets.only(left: 60),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            gradient: isQuickReply
                ? const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C5BE8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [_roseGold, Color(0xFFB8628E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20), bottomRight: Radius.circular(5),
            ),
            boxShadow: [
              BoxShadow(
                color: (isQuickReply ? _lavender : _roseGold).withValues(alpha: 0.40),
                blurRadius: 16, offset: const Offset(0, 4), spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45)),
        ),
      ),
    );
  }
}

// ─── Special Bubble ───────────────────────────────────────────────────────────

class _SpecialBubble extends StatefulWidget {
  final String content;
  final bool isMe;
  final HeartSyncThemeData td;
  const _SpecialBubble({required this.content, required this.isMe, required this.td});
  @override State<_SpecialBubble> createState() => _SpecialBubbleState();
}

class _SpecialBubbleState extends State<_SpecialBubble> with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimX;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _shimX = Tween(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final td = widget.td;
    if (td.isLight) {
      // Sweetheart: soft pastel love note card
      return Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _shimX,
          builder: (_, __) => Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            margin: EdgeInsets.only(left: widget.isMe ? 40 : 0, right: widget.isMe ? 0 : 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: td.primary.withValues(alpha: 0.3), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment(_shimX.value, 0),
                end: Alignment(_shimX.value + 1.2, 0.6),
                colors: [td.surface, td.primary.withValues(alpha: 0.06), td.surface],
              ),
              boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              Container(
                width: double.infinity, height: 26,
                decoration: BoxDecoration(
                  color: td.primary.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(bottom: BorderSide(color: td.primary.withValues(alpha: 0.20))),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('💌', style: TextStyle(fontSize: 13)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Text(
                  widget.content,
                  style: TextStyle(color: td.primary, fontSize: 16, height: 1.6, fontWeight: FontWeight.w600, letterSpacing: 0.02),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),
        ),
      );
    }

    // Dark: lavender shimmer envelope (original)
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _shimX,
        builder: (_, __) => Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          margin: EdgeInsets.only(
            left: widget.isMe ? 40 : 0,
            right: widget.isMe ? 0 : 40,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _lavender.withValues(alpha: 0.5), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment(_shimX.value, 0),
              end: Alignment(_shimX.value + 1.2, 0.6),
              colors: const [Color(0xFF160E28), Color(0xFF221540), Color(0xFF160E28)],
            ),
            boxShadow: [BoxShadow(color: _lavender.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Container(
              width: double.infinity, height: 24,
              decoration: BoxDecoration(
                color: _lavender.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: _lavender.withValues(alpha: 0.25))),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('💌', style: TextStyle(fontSize: 12)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                widget.content,
                style: TextStyle(color: _lavender.withValues(alpha: 0.95), fontSize: 16, height: 1.6, fontWeight: FontWeight.w500, letterSpacing: 0.02),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
