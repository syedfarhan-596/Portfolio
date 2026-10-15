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

/// A two-stop gradient from the brightest token down to a surface's base
/// tone — the visible "sheen" a pane of glass catching light would show,
/// standing in for what would otherwise be a flat, characterless fill.
/// Shared by GlassCard, the bottom sheet and the nav bar so every glass
/// surface in the app reads consistently.
LinearGradient glassSheen(AppTokens t, {bool strong = false}) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [t.glassHighlight, strong ? t.glassFillStrong : t.glassFill],
    );

/// A translucent surface: no backdrop blur (blur is expensive to composite
/// and was causing jank on lower-end devices) — just a gradient fill,
/// hairline border, and a soft drop shadow for depth.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
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
    this.onTap,
    this.strong = false,
    this.gradient,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? glassSheen(t, strong: strong),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: t.glassBorder, width: 1),
      ),
      child: child,
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
