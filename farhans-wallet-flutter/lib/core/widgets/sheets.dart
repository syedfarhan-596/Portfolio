import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'glass.dart';

/// Frosted modal bottom sheet wrapper.
Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  final t = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Corners.xl)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: Blurs.heavy, sigmaY: Blurs.heavy),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.glassFillStrong,
                border: Border(top: BorderSide(color: t.glassBorder)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Corners.xl)),
              ),
              padding: EdgeInsets.only(
                left: Insets.lg,
                right: Insets.lg,
                top: Insets.sm,
                bottom: Insets.lg + MediaQuery.of(ctx).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: Insets.md),
                    decoration: BoxDecoration(
                      color: t.textLow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Corners.pill),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<T?> showGlassPicker<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) optionLabel,
  T? selected,
  IconData Function(T)? optionIcon,
}) {
  final t = context.tokens;
  return showGlassSheet<T>(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm, left: 4),
          child: Text(title, style: context.text.titleMedium),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final o = options[i];
              final isSel = o == selected;
              return Pressable(
                onTap: () => Navigator.pop(ctx, o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSel ? t.accentA.withValues(alpha: 0.18) : t.glassFill,
                    borderRadius: BorderRadius.circular(Corners.sm),
                    border: Border.all(
                        color: isSel ? t.accentA.withValues(alpha: 0.5) : t.glassBorder),
                  ),
                  child: Row(
                    children: [
                      if (optionIcon != null) ...[
                        Icon(optionIcon(o), size: IconSizes.md, color: t.textHigh),
                        const SizedBox(width: Insets.sm),
                      ],
                      Expanded(
                        child: Text(optionLabel(o),
                            style: context.text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: t.textHigh)),
                      ),
                      if (isSel) Icon(Icons.check_rounded, color: t.accentA),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
