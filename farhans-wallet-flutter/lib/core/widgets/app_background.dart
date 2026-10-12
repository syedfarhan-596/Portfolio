import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Ambient gradient backdrop with softly coloured blobs, pre-blurred once
/// behind the whole app. Everything "glassy" in the app (cards, sheets, the
/// nav bar) is just a translucent fill sitting on top of this — none of
/// them run their own BackdropFilter. A single blur paid once here, versus
/// one per card, is what makes the frosted look affordable: the old design
/// ran a BackdropFilter per card (and the background animated forever on
/// top of that), which is what was costing real frames on lower-end
/// devices. Static (no perpetual animation) for the same reason.
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
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox.expand(),
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
