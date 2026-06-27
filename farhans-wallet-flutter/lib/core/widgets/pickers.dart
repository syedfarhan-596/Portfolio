import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../utils/icon_map.dart';

class ColorPickerRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const ColorPickerRow({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppIcons.palette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final hex = AppIcons.palette[i];
          final c = AppIcons.parseColor(hex);
          final sel = hex == selected;
          return GestureDetector(
            onTap: () => onSelect(hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? t.textHigh : Colors.transparent, width: 3),
              ),
            ),
          );
        },
      ),
    );
  }
}

class IconPickerRow extends StatelessWidget {
  final String selected;
  final Color tint;
  final ValueChanged<String> onSelect;
  const IconPickerRow({super.key, required this.selected, required this.tint, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppIcons.pickable.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final key = AppIcons.pickable[i];
          final sel = key == selected;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: sel ? tint.withValues(alpha: 0.22) : t.glassFill,
                borderRadius: BorderRadius.circular(Corners.sm),
                border: Border.all(color: sel ? tint : t.glassBorder, width: sel ? 2 : 1),
              ),
              child: Icon(AppIcons.of(key), color: sel ? tint : t.textMid),
            ),
          );
        },
      ),
    );
  }
}
