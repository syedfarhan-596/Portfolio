import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Ambient gradient backdrop with softly coloured blobs. Everything glassy
/// in the app is layered on top of this. Static (no perpetual animation) —
/// a never-ending repaint loop was a real cost on lower-end devices.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

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
            child: Stack(
              children: [
                _blob(t.blobA, 320, const Alignment(-1.1, -0.9)),
                _blob(t.blobB, 280, const Alignment(1.15, -0.2)),
                _blob(t.blobC, 300, const Alignment(-0.8, 1.0)),
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
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
