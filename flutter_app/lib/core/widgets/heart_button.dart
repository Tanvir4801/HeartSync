import 'package:flutter/material.dart';

class HeartButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final String? label;

  const HeartButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 64,
    this.color = const Color(0xFFE05C7E),
    this.label,
  });

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0),  weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTap() async {
    if (widget.onPressed == null) return;
    _ctrl.forward(from: 0);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: ClipPath(
            clipper: _HeartClipper(),
            child: Container(
              width: widget.size,
              height: widget.size * 0.92,
              color: widget.color.withValues(alpha: 0.18),
              child: Center(child: widget.child),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
          Text(widget.label!, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8BAA))),
        ],
      ]),
    );
  }
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.88)
      ..cubicTo(w * 0.05, h * 0.6, w * 0.0, h * 0.35, w * 0.0, h * 0.28)
      ..cubicTo(w * 0.0, h * 0.1,  w * 0.2, h * 0.0,  w * 0.38, h * 0.0)
      ..cubicTo(w * 0.45, h * 0.0, w * 0.5, h * 0.08, w * 0.5, h * 0.18)
      ..cubicTo(w * 0.5, h * 0.08, w * 0.55, h * 0.0, w * 0.62, h * 0.0)
      ..cubicTo(w * 0.8, h * 0.0,  w * 1.0, h * 0.1,  w * 1.0, h * 0.28)
      ..cubicTo(w * 1.0, h * 0.35, w * 0.95, h * 0.6, w * 0.5, h * 0.88)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_HeartClipper old) => false;
}
