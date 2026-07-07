import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HeartSync Cute Romantic Palette
// Matches the soft lavender + blush dashboard UI
// ─────────────────────────────────────────────────────────────────────────────

const _rosePink = Color(0xFFFF8FB1);
const _softRose = Color(0xFFFFB3C9);

const _lavender = Color(0xFF9B7BFF);
const _softLavender = Color(0xFFBDA7FF);

const _deepPurple = Color(0xFF523B72);
const _mutedPurple = Color(0xFFA897BA);

const _bubbleWhite = Color(0xFFFFFBFD);
const _bubbleLavender = Color(0xFFF2EBFF);
const _bubblePink = Color(0xFFFFEEF5);

const _successGreen = Color(0xFF62C9A5);

// ─────────────────────────────────────────────────────────────────────────────
// Special romantic message detection
// ─────────────────────────────────────────────────────────────────────────────

bool isSpecialMessage(String content) {
  final lower = content.toLowerCase().trim();

  return lower.contains('i love you') ||
      lower.contains('love you') ||
      lower.contains('i miss you') ||
      lower.contains('miss you') ||
      lower.contains('love you so');
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────

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
    // Keep watching your app theme so this file remains compatible
    // with your existing ThemeProvider setup.
    context.watch<ThemeProvider>();

    final special = isSpecialMessage(content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (special)
            _SpecialLoveBubble(
              content: content,
              isMe: isMe,
            )
          else if (isMe)
            _SentBubble(
              content: content,
              isQuickReply: isQuickReply,
            )
          else
            _ReceivedBubble(
              content: content,
            ),

          const SizedBox(height: 4),

          _MessageMeta(
            sentAt: sentAt,
            isMe: isMe,
            readAt: readAt,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Received Bubble
// Soft cloud-white bubble with lavender tint
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final String content;

  const _ReceivedBubble({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.74;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 48),
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bubbleWhite,
                _bubbleLavender,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(9),
            ),
            border: Border.all(
              color: _lavender.withValues(alpha: 0.16),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _lavender.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: _deepPurple,
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent Bubble
// Romantic lavender → pink gradient
// ─────────────────────────────────────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final String content;
  final bool isQuickReply;

  const _SentBubble({
    required this.content,
    required this.isQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.74;

   final List<Color> gradientColors = isQuickReply
    ? const [
        Color(0xFFB9A4FF),
        Color(0xFF9B7BFF),
      ]
    : const [
        Color(0xFFA98CFF),
        Color(0xFFFF91B8),
      ];

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 48),
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(9),
            ),
            boxShadow: [
              BoxShadow(
                color: isQuickReply
                    ? _lavender.withValues(alpha: 0.22)
                    : _rosePink.withValues(alpha: 0.24),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Time + Read Status
// ─────────────────────────────────────────────────────────────────────────────

class _MessageMeta extends StatelessWidget {
  final DateTime sentAt;
  final bool isMe;
  final DateTime? readAt;

  const _MessageMeta({
    required this.sentAt,
    required this.isMe,
    required this.readAt,
  });

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 14,
        right: isMe ? 14 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(sentAt),
            style: const TextStyle(
              fontSize: 10,
              color: _mutedPurple,
              fontWeight: FontWeight.w400,
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 4),

            Icon(
              readAt != null
                  ? Icons.done_all_rounded
                  : Icons.done_rounded,
              size: 13,
              color: readAt != null
                  ? _successGreen
                  : _mutedPurple,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Special Romantic Bubble
// Used for:
// "I love you"
// "Love you"
// "I miss you"
// etc.
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialLoveBubble extends StatefulWidget {
  final String content;
  final bool isMe;

  const _SpecialLoveBubble({
    required this.content,
    required this.isMe,
  });

  @override
  State<_SpecialLoveBubble> createState() =>
      _SpecialLoveBubbleState();
}

class _SpecialLoveBubbleState extends State<_SpecialLoveBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.68;

    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ScaleTransition(
        scale: _pulse,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: Container(
            margin: EdgeInsets.only(
              left: widget.isMe ? 55 : 0,
              right: widget.isMe ? 0 : 55,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              gradient: widget.isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB89CFF),
                        Color(0xFFFF9FC1),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFBFD),
                        Color(0xFFFFEEF5),
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: Radius.circular(
                  widget.isMe ? 24 : 8,
                ),
                bottomRight: Radius.circular(
                  widget.isMe ? 8 : 24,
                ),
              ),
              border: widget.isMe
                  ? null
                  : Border.all(
                      color: _rosePink.withValues(alpha: 0.25),
                    ),
              boxShadow: [
                BoxShadow(
                  color: _rosePink.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isMe ? '💗' : '💌',
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: Text(
                    widget.content,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white
                          : _deepPurple,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}