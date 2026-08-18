import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'glass.dart';

/// Modal bottom sheet wrapper. Flat fill instead of a backdrop blur — blur
/// is expensive to composite and was causing jank on lower-end devices.
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
    // A bounded max height is required so the ListView below actually has
    // room to scroll instead of trying to lay out every option at full
    // height inside an unconstrained sheet (which just overflows/clips
    // instead of scrolling when the list is long, e.g. the category list).
    ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
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
    ),
  );
}
