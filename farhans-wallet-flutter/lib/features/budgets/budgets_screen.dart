import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

/// Lets the user cap monthly spend per expense category, and shows how
/// close they are to that cap so far this month.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;

    if (data == null) {
      return const DetailScaffold(title: 'Budgets', child: Center(child: CircularProgressIndicator()));
    }

    final expenseCats = data.categoriesOfType(TxnType.expense);
    final statusByCategory = {for (final s in data.budgetStatuses) s.category.id!: s};

    return DetailScaffold(
      title: 'Budgets',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          Text(
            'Set a monthly cap on any category. It tracks against what you\'ve '
            'actually spent this calendar month, resetting automatically each month.',
            style: context.text.bodySmall?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.md),
          ...expenseCats.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.xs),
                child: _CategoryBudgetRow(
                  category: c,
                  status: statusByCategory[c.id],
                  onTap: () => showGlassSheet(
                    context,
                    _BudgetEditor(category: c, status: statusByCategory[c.id], ref: ref),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  final Category category;
  final BudgetStatus? status;
  final VoidCallback onTap;
  const _CategoryBudgetRow({required this.category, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = AppIcons.parseColor(category.colorHex);
    final s = status;

    return GlassCard(
      onTap: onTap,
      radius: Corners.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: AppIcons.of(category.icon), color: color),
              const SizedBox(width: Insets.sm),
              Expanded(child: Text(category.name, style: context.text.titleSmall)),
              if (s == null)
                Text('No budget set', style: context.text.bodySmall?.copyWith(color: t.textMid))
              else
                Text(
                  '${Money.short(s.spent)} / ${Money.short(s.budget.monthlyLimit)}',
                  style: context.text.titleSmall?.copyWith(
                    color: s.isOver ? t.danger : t.textHigh,
                  ),
                ),
            ],
          ),
          if (s != null) ...[
            const SizedBox(height: Insets.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Corners.pill),
              child: LinearProgressIndicator(
                value: s.pct.clamp(0.0, 1.0).toDouble(),
                minHeight: 7,
                backgroundColor: t.glassFill,
                valueColor: AlwaysStoppedAnimation(
                  s.isOver ? t.danger : (s.isNearLimit ? t.warning : t.success),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  final Category category;
  final BudgetStatus? status;
  final WidgetRef ref;
  const _BudgetEditor({required this.category, required this.status, required this.ref});

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController _limit = TextEditingController(
      text: widget.status == null ? '' : _trim(widget.status!.budget.monthlyLimit));

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.status != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget for ${widget.category.name}', style: context.text.titleMedium),
        const SizedBox(height: Insets.md),
        AppTextField(label: 'Monthly limit (₹)', controller: _limit, amount: true),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            if (editing)
              Expanded(
                child: SecondaryButton(
                  label: 'Remove',
                  onPressed: () {
                    widget.ref.read(walletProvider.notifier).deleteBudget(widget.status!.budget);
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
                  final limit = double.tryParse(_limit.text);
                  if (limit == null || limit <= 0) return;
                  widget.ref.read(walletProvider.notifier).saveBudget(Budget(
                        id: widget.status?.budget.id,
                        categoryId: widget.category.id!,
                        monthlyLimit: limit,
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
