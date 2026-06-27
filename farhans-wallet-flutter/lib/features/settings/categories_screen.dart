import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/segmented.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(walletProvider).value;
    final cats = data?.categories ?? [];
    final expense = cats.where((c) => c.type == TxnType.expense).toList();
    final income = cats.where((c) => c.type == TxnType.income).toList();

    return DetailScaffold(
      title: 'Categories',
      trailing: GlassIconButton(
        icon: Icons.add_rounded,
        onPressed: () => _edit(context, ref, null),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          const SectionHeader('Expense categories'),
          const SizedBox(height: Insets.xs),
          ...expense.map((c) => _tile(context, ref, c)),
          const SizedBox(height: Insets.md),
          const SectionHeader('Income categories'),
          const SizedBox(height: Insets.xs),
          ...income.map((c) => _tile(context, ref, c)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, Category c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xs),
      child: GlassCard(
        onTap: () => _edit(context, ref, c),
        padding: const EdgeInsets.all(Insets.sm),
        radius: Corners.md,
        child: Row(
          children: [
            IconBadge(icon: AppIcons.of(c.icon), color: AppIcons.parseColor(c.colorHex)),
            const SizedBox(width: Insets.sm),
            Expanded(child: Text(c.name, style: context.text.titleSmall)),
            Icon(Icons.chevron_right_rounded, color: context.tokens.textMid),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref, Category? category) {
    showGlassSheet(context, _CategoryEditor(category: category, ref: ref));
  }
}

class _CategoryEditor extends StatefulWidget {
  final Category? category;
  final WidgetRef ref;
  const _CategoryEditor({required this.category, required this.ref});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.category?.name ?? '');
  late TxnType _type = widget.category?.type ?? TxnType.expense;
  late String _color = widget.category?.colorHex ?? AppIcons.palette.first;
  late String _icon = widget.category?.icon ?? 'category';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(editing ? 'Edit category' : 'New category', style: context.text.titleMedium),
        const SizedBox(height: Insets.md),
        AppTextField(label: 'Name', controller: _name),
        const SizedBox(height: Insets.sm),
        GlassSegmented<TxnType>(
          values: const [TxnType.expense, TxnType.income],
          selected: _type,
          label: (v) => v == TxnType.expense ? 'Expense' : 'Income',
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: Insets.md),
        Text('Color', style: context.text.labelMedium),
        const SizedBox(height: Insets.xs),
        ColorPickerRow(selected: _color, onSelect: (c) => setState(() => _color = c)),
        const SizedBox(height: Insets.md),
        Text('Icon', style: context.text.labelMedium),
        const SizedBox(height: Insets.xs),
        IconPickerRow(
            selected: _icon, tint: AppIcons.parseColor(_color), onSelect: (i) => setState(() => _icon = i)),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            if (editing)
              Expanded(
                child: SecondaryButton(
                  label: 'Delete',
                  onPressed: () {
                    widget.ref.read(walletProvider.notifier).deleteCategory(widget.category!);
                    Navigator.pop(context);
                  },
                ),
              ),
            if (editing) const SizedBox(width: Insets.sm),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Save',
                onPressed: () {
                  if (_name.text.trim().isEmpty) return;
                  final base = widget.category ?? Category(name: _name.text, type: _type);
                  widget.ref.read(walletProvider.notifier).saveCategory(base.copyWith(
                        name: _name.text.trim(),
                        type: _type,
                        colorHex: _color,
                        icon: _icon,
                      ));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
