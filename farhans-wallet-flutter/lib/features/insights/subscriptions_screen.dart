import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

/// Shows recurring/subscription-like spending the app noticed on its own —
/// same merchant, same account, repeating at a steady interval and amount
/// — with no manual tagging required. Detected fresh from transaction
/// history on every load; nothing here is stored separately.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;

    if (data == null) {
      return const DetailScaffold(
          title: 'Subscriptions', child: Center(child: CircularProgressIndicator()));
    }

    final series = data.recurringSeries;
    final expenseSeries = series.where((r) => r.type == TxnType.expense).toList();

    return DetailScaffold(
      title: 'Subscriptions & recurring',
      child: series.isEmpty
          ? const EmptyState(
              icon: Icons.autorenew_rounded,
              title: 'Nothing recurring spotted yet',
              subtitle: 'Once the same merchant charges the same account at a steady interval '
                  '— weekly, monthly or yearly — it shows up here automatically.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
              children: [
                if (expenseSeries.isNotEmpty) ...[
                  GlassCard(
                    strong: true,
                    child: Row(
                      children: [
                        IconBadge(icon: Icons.autorenew_rounded, color: t.accentA),
                        const SizedBox(width: Insets.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('~${Money.format(data.monthlyRecurringTotal)}/month',
                                  style: context.text.titleMedium),
                              Text('across ${expenseSeries.length} recurring charge'
                                  '${expenseSeries.length == 1 ? '' : 's'}',
                                  style: context.text.bodySmall?.copyWith(color: t.textMid)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                ],
                Text(
                  'Sorted by what\'s due soonest. "Spotted" means only two charges so far — '
                  'give it one more cycle to be sure.',
                  style: context.text.bodySmall?.copyWith(color: t.textMid),
                ),
                const SizedBox(height: Insets.md),
                ...series.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: Insets.xs),
                      child: _SeriesRow(series: r, account: data.accountById[r.accountId]),
                    )),
              ],
            ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  final RecurringSeries series;
  final Account? account;
  const _SeriesRow({required this.series, required this.account});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isIncome = series.type == TxnType.income;
    final daysLeft =
        ((series.nextExpectedDate - DateTime.now().millisecondsSinceEpoch) / 86400000).round();
    final due = series.isOverdue
        ? 'Overdue — may have stopped'
        : daysLeft <= 0
            ? 'Due today'
            : daysLeft == 1
                ? 'Due tomorrow'
                : 'Due in $daysLeft days';

    return GlassCard(
      radius: Corners.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (account != null)
            IconBadge(icon: AppIcons.of(account!.icon), color: AppIcons.parseColor(account!.colorHex))
          else
            IconBadge(icon: Icons.autorenew_rounded, color: t.textMid),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.merchant,
                    style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Pill(label: series.cadence.label),
                    if (!series.confident) Pill(label: 'Spotted', color: t.warning),
                    Pill(
                      label: due,
                      color: series.isOverdue ? t.textMid : t.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            '${isIncome ? '+' : '-'}${Money.short(series.averageAmount)}',
            style: context.text.titleSmall?.copyWith(color: isIncome ? t.success : t.danger),
          ),
        ],
      ),
    );
  }
}
