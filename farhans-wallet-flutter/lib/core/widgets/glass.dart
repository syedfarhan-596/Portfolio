import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Scales down briefly on press — replaces the default Material ripple with a
/// softer, more premium tactile feel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A frosted-glass surface: real backdrop blur, translucent fill, hairline
/// border and a soft top highlight for depth.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final bool strong;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.md),
    this.radius = Corners.lg,
    this.blur = Blurs.card,
    this.onTap,
    this.strong = false,
    this.gradient,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? (strong ? t.glassFillStrong : t.glassFill) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(color: t.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: t.softShadow,
      ),
      child: content,
    );

    final widget = margin == null ? shadowed : Padding(padding: margin!, child: shadowed);
    return onTap == null ? widget : Pressable(onTap: onTap, child: widget);
  }
}
