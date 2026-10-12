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
import '../../core/widgets/pickers.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    final goals = data?.goals ?? const <SavingsGoal>[];

    return DetailScaffold(
      title: 'Savings goals',
      trailing: GlassIconButton(
        icon: Icons.add_rounded,
        onPressed: () => _edit(context, ref, null),
      ),
      child: goals.isEmpty
          ? const EmptyState(
              icon: Icons.savings_rounded,
              title: 'No goals yet',
              subtitle: 'Set a target — a trip, an emergency fund, a gadget — and track '
                  'how close you are to it.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
              children: [
                for (final g in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: _GoalCard(
                      goal: g,
                      onTap: () => _edit(context, ref, g),
                      onAddMoney: () => _quickAdd(context, ref, g),
                    ),
                  ),
              ],
            ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref, SavingsGoal? goal) {
    showGlassSheet(context, _GoalEditor(goal: goal, ref: ref));
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref, SavingsGoal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tokens.bgBottom,
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await ref.read(walletProvider.notifier).contributeToGoal(goal, amount);
    }
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;
  final VoidCallback onAddMoney;
  const _GoalCard({required this.goal, required this.onTap, required this.onAddMoney});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = AppIcons.parseColor(goal.colorHex);
    return GlassCard(
      onTap: onTap,
      radius: Corners.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: AppIcons.of(goal.icon), color: color),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: Text(goal.name,
                                style: context.text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        if (goal.achieved) ...[
                          const SizedBox(width: 6),
                          Pill(label: 'Reached!', color: t.success),
                        ],
                      ],
                    ),
                    if (goal.targetDate != null)
                      Text(_targetDateLabel(goal.targetDate!),
                          style: context.text.bodySmall?.copyWith(color: t.textMid)),
                  ],
                ),
              ),
              if (!goal.achieved)
                IconButton(
                  onPressed: onAddMoney,
                  tooltip: 'Add money',
                  icon: Icon(Icons.add_circle_rounded, color: t.accentA),
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Corners.pill),
            child: LinearProgressIndicator(
              value: goal.pct.toDouble(),
              minHeight: 8,
              backgroundColor: t.glassFill,
              valueColor: AlwaysStoppedAnimation(goal.achieved ? t.success : color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Money.format(goal.savedAmount)} of ${Money.format(goal.targetAmount)} saved',
            style: context.text.bodySmall?.copyWith(color: t.textMid),
          ),
        ],
      ),
    );
  }

  String _targetDateLabel(int ms) {
    final days = DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now()).inDays;
    if (days < 0) return 'Target date passed';
    if (days == 0) return 'Target date is today';
    return 'By ${Dates.date(ms)} ($days days left)';
  }
}

class _GoalEditor extends StatefulWidget {
  final SavingsGoal? goal;
  final WidgetRef ref;
  const _GoalEditor({required this.goal, required this.ref});

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.goal?.name ?? '');
  late final TextEditingController _target =
      TextEditingController(text: widget.goal == null ? '' : _trim(widget.goal!.targetAmount));
  late final TextEditingController _saved =
      TextEditingController(text: widget.goal == null ? '0' : _trim(widget.goal!.savedAmount));
  late String _color = widget.goal?.colorHex ?? AppIcons.palette.first;
  late String _icon = widget.goal?.icon ?? 'savings';
  late DateTime? _targetDate =
      widget.goal?.targetDate != null ? DateTime.fromMillisecondsSinceEpoch(widget.goal!.targetDate!) : null;

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.goal != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(editing ? 'Edit goal' : 'New savings goal', style: context.text.titleMedium),
        const SizedBox(height: Insets.md),
        AppTextField(label: 'Name', controller: _name),
        const SizedBox(height: Insets.sm),
        AppTextField(label: 'Target amount (₹)', controller: _target, amount: true),
        const SizedBox(height: Insets.sm),
        AppTextField(label: 'Already saved (₹)', controller: _saved, amount: true),
        const SizedBox(height: Insets.sm),
        Pressable(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target date (optional)', style: context.text.bodyLarge),
              Row(
                children: [
                  Text(
                    _targetDate == null
                        ? 'None'
                        : Dates.date(_targetDate!.millisecondsSinceEpoch),
                    style: TextStyle(color: context.tokens.accentA, fontWeight: FontWeight.w600),
                  ),
                  if (_targetDate != null)
                    IconButton(
                      onPressed: () => setState(() => _targetDate = null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
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
                    widget.ref.read(walletProvider.notifier).deleteGoal(widget.goal!);
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
                  final target = double.tryParse(_target.text) ?? 0;
                  if (target <= 0) return;
                  final saved = double.tryParse(_saved.text) ?? 0;
                  final base = widget.goal ??
                      SavingsGoal(
                        name: _name.text,
                        targetAmount: target,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                      );
                  widget.ref.read(walletProvider.notifier).saveGoal(base
                      .copyWith(
                        name: _name.text.trim(),
                        targetAmount: target,
                        savedAmount: saved,
                        colorHex: _color,
                        icon: _icon,
                      )
                      .withTargetDate(_targetDate?.millisecondsSinceEpoch));
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
