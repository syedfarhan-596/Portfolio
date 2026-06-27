import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import 'sheets.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool amount;
  final Widget? prefix;
  final String? initialValue;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.amount = false,
    this.prefix,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.sm),
          borderSide: BorderSide(color: c, width: 1.2),
        );
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType ??
          (amount ? const TextInputType.numberWithOptions(decimal: true) : null),
      inputFormatters: amount
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      maxLines: maxLines,
      style: context.text.bodyLarge?.copyWith(color: t.textHigh, fontWeight: FontWeight.w600),
      cursorColor: t.accentA,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: t.textMid),
        floatingLabelStyle: TextStyle(color: t.accentA, fontWeight: FontWeight.w600),
        prefixIcon: prefix,
        filled: true,
        fillColor: t.glassFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.md),
        enabledBorder: border(t.glassBorder),
        focusedBorder: border(t.accentA),
      ),
    );
  }
}

class AppSelectField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;
  final IconData Function(T)? optionIcon;

  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.optionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: () async {
        final picked = await showGlassPicker<T>(
          context,
          title: label,
          options: options,
          optionLabel: optionLabel,
          selected: value,
          optionIcon: optionIcon,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.textMid),
          filled: true,
          fillColor: t.glassFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.md),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corners.sm),
            borderSide: BorderSide(color: t.glassBorder, width: 1.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select' : optionLabel(value as T),
                style: context.text.bodyLarge?.copyWith(
                    color: value == null ? t.textLow : t.textHigh, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded, color: t.textMid),
          ],
        ),
      ),
    );
  }
}
