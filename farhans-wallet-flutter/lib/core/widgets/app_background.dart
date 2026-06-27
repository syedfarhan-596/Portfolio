import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Ambient gradient backdrop with softly drifting colour blobs. Everything
/// glassy in the app is layered on top of this so blur picks up real colour.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.bgTop, t.bgBottom],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final a = _c.value * 2 * math.pi;
                return Stack(
                  children: [
                    _blob(t.blobA, 320, Alignment(-1.1 + 0.08 * math.sin(a), -0.9 + 0.06 * math.cos(a))),
                    _blob(t.blobB, 280, Alignment(1.15 + 0.06 * math.cos(a), -0.2 + 0.08 * math.sin(a))),
                    _blob(t.blobC, 300, Alignment(-0.8 + 0.07 * math.cos(a), 1.0 + 0.05 * math.sin(a))),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _blob(Color color, double size, Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
