import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Ambient gradient backdrop with softly coloured blobs, pre-blurred once
/// behind the whole app. Everything "glassy" in the app (cards, sheets, the
/// nav bar) is just a translucent fill sitting on top of this — none of
/// them run their own blur. A single blur paid once here, versus one per
/// card, is what makes the frosted look affordable: the old design ran a
/// BackdropFilter per card (and the background animated forever on top of
/// that), which is what was costing real frames on lower-end devices.
/// Static (no perpetual animation) for the same reason.
///
/// Deliberately blurred with [ImageFiltered], not [BackdropFilter]:
/// BackdropFilter blurs by sampling the live compositor scene behind it
/// every frame, which is meant for blurring something dynamic (e.g. content
/// scrolling behind a frosted pane). Since this background never changes,
/// that sampling is both wasted work and — on some renderers (Impeller in
/// particular) — prone to leaking stale frames from elsewhere on screen
/// into the blur when scrolling content sits above it, which showed up as
/// ghosted nav-bar icons bleeding onto list rows. ImageFiltered blurs only
/// its own subtree's already-rendered pixels, so it has nothing to sample
/// from the rest of the screen and can't ghost like that, and — since that
/// subtree is static — Flutter can cache the blurred result instead of
/// recomputing it every frame.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Stack(
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
                      child: Stack(
                        children: [
                          _blob(t.blobA, 320, const Alignment(-1.1, -0.9)),
                          _blob(t.blobB, 280, const Alignment(1.15, -0.2)),
                          _blob(t.blobC, 300, const Alignment(-0.8, 1.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
