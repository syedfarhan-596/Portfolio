import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../utils/format.dart';
import 'glass.dart';

/// Rounded tinted icon container used throughout the app.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: Insets.xs, bottom: Insets.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.text.titleMedium),
          if (actionLabel != null && onAction != null)
            Pressable(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        children: [
          IconBadge(icon: icon, color: t.accentA, size: 76),
          const SizedBox(height: Insets.md),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Insets.xxs),
          Text(subtitle,
              style: context.text.bodyMedium?.copyWith(color: t.textMid),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Smoothly tweens a money value when it changes.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final bool short;
  const AnimatedMoney(this.value, {super.key, this.style, this.short = false});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Motion.slow,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(short ? Money.short(v) : Money.format(v), style: style),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const Pill({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = color ?? t.accentA;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
