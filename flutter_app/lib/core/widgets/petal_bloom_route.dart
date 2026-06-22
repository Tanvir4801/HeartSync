import 'package:flutter/material.dart';

PageRouteBuilder<T> petalBloomRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incoming = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn);

      return FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(incoming),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(incoming),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(outgoing),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.96).animate(outgoing),
              child: Stack(children: [
                child,
                IgnorePointer(
                  child: FadeTransition(
                    opacity: Tween(begin: 0.12, end: 0.0).animate(
                      CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    },
  );
}
