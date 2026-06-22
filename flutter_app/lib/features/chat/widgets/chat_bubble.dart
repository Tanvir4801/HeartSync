import 'package:flutter/material.dart';
import '../../../core/theme.dart';

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
    final special = isSpecialMessage(content);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (special)
            _SpecialBubble(content: content, isMe: isMe)
          else if (isMe)
            _SentBubble(content: content, isQuickReply: isQuickReply)
          else
            _ReceivedBubble(content: content),

          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 14, right: isMe ? 14 : 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  readAt != null ? Icons.done_all : Icons.done,
                  size: 12,
                  color: readAt != null ? AppTheme.success : AppTheme.textMuted,
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Received Bubble (cloud shape with left tail) ─────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final String content;
  const _ReceivedBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Left tail
          CustomPaint(
            size: const Size(10, 18),
            painter: _TailPainter(color: AppTheme.surface2, isLeft: true),
          ),
          Flexible(child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Text(content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.45)),
          )),
        ]),
      ),
    );
  }
}

// ─── Sent Bubble (love letter — gradient with right tail) ─────────────────────

class _SentBubble extends StatelessWidget {
  final String content;
  final bool isQuickReply;
  const _SentBubble({required this.content, required this.isQuickReply});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            decoration: BoxDecoration(
              gradient: isQuickReply
                  ? const LinearGradient(colors: [Color(0xFFB8449C), Color(0xFFE05C7E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : const LinearGradient(colors: [Color(0xFFE8A598), Color(0xFFD47B8E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: const Color(0xFFE8A598).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45)),
          )),
          // Right tail
          CustomPaint(
            size: const Size(10, 18),
            painter: _TailPainter(color: const Color(0xFFD47B8E), isLeft: false),
          ),
        ]),
      ),
    );
  }
}

// ─── Special Bubble (envelope for "I love you" / "I miss you") ───────────────

class _SpecialBubble extends StatefulWidget {
  final String content;
  final bool isMe;
  const _SpecialBubble({required this.content, required this.isMe});
  @override
  State<_SpecialBubble> createState() => _SpecialBubbleState();
}

class _SpecialBubbleState extends State<_SpecialBubble> with SingleTickerProviderStateMixin {
  late AnimationController _glimmer;
  late Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();
    _glimmer = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _shimmerX = Tween(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _glimmer, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _glimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _shimmerX,
        builder: (_, __) => Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3C98B).withValues(alpha: 0.5), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment(_shimmerX.value, 0),
              end: Alignment(_shimmerX.value + 1.2, 0.6),
              colors: const [Color(0xFF2A1D00), Color(0xFF3D2A05), Color(0xFF2A1D00)],
            ),
          ),
          child: Column(children: [
            // Envelope flap decoration
            Container(
              width: double.infinity,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF3C98B).withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(bottom: BorderSide(color: Color(0xFFF3C98B), width: 0.5)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('💌', style: TextStyle(fontSize: 11)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                widget.content,
                style: const TextStyle(
                  color: Color(0xFFF3C98B), fontSize: 16, height: 1.6,
                  fontWeight: FontWeight.w500, letterSpacing: 0.02,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Tail Painter ─────────────────────────────────────────────────────────────

class _TailPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  const _TailPainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height * 0.5);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height * 0.5);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
