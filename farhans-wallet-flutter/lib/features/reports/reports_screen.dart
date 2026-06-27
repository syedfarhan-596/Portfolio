import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _month;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(walletProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final months = <String, String>{};
        for (final tx in data.confirmed) {
          months[Dates.monthKey(tx.dateTime)] = Dates.month(tx.dateTime);
        }
        final monthKeys = months.keys.toList()..sort((a, b) => b.compareTo(a));
        _month ??= monthKeys.isNotEmpty ? monthKeys.first : null;

        final monthTxns = data.confirmed
            .where((tx) => _month == null || Dates.monthKey(tx.dateTime) == _month)
            .toList();
        final expense = monthTxns.where((tx) => tx.type == TxnType.expense).toList();
        final income = monthTxns.where((tx) => tx.type == TxnType.income).toList();
        final totalExpense = expense.fold<double>(0, (s, tx) => s + tx.amount);
        final totalIncome = income.fold<double>(0, (s, tx) => s + tx.amount);

        final byCat = <int?, double>{};
        for (final tx in expense) {
          byCat[tx.categoryId] = (byCat[tx.categoryId] ?? 0) + tx.amount;
        }
        final catEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        final byAcc = <int, double>{};
        for (final tx in expense) {
          byAcc[tx.accountId] = (byAcc[tx.accountId] ?? 0) + tx.amount;
        }
        final accEntries = byAcc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 120),
          children: [
            Text('Reports', style: context.text.headlineMedium),
            const SizedBox(height: Insets.md),
            if (monthKeys.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: monthKeys
                      .map((k) => Padding(
                            padding: const EdgeInsets.only(right: Insets.xs),
                            child: _chip(months[k]!, _month == k, () => setState(() => _month = k)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(child: _bigStat('Income', totalIncome, t.success)),
                const SizedBox(width: Insets.sm),
                Expanded(child: _bigStat('Expense', totalExpense, t.danger)),
              ],
            ),
            const SizedBox(height: Insets.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net this period', style: context.text.titleMedium),
                  const SizedBox(height: 6),
                  Builder(builder: (_) {
                    final net = totalIncome - totalExpense;
                    return Text(Money.format(net),
                        style: context.text.headlineMedium
                            ?.copyWith(color: net >= 0 ? t.success : t.danger));
                  }),
                ],
              ),
            ),
            if (catEntries.isNotEmpty && totalExpense > 0) ...[
              const SizedBox(height: Insets.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending by category', style: context.text.titleMedium),
                    const SizedBox(height: Insets.md),
                    ...catEntries.map((e) {
                      final cat = e.key != null ? data.categoryById[e.key] : null;
                      return _bar(
                        cat?.name ?? 'Uncategorized',
                        e.value,
                        e.value / totalExpense,
                        AppIcons.parseColor(cat?.colorHex ?? '#636E72'),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (accEntries.isNotEmpty && totalExpense > 0) ...[
              const SizedBox(height: Insets.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending by account', style: context.text.titleMedium),
                    const SizedBox(height: Insets.md),
                    ...accEntries.map((e) {
                      final acc = data.accountById[e.key];
                      return _bar(
                        acc?.name ?? 'Unknown',
                        e.value,
                        e.value / totalExpense,
                        AppIcons.parseColor(acc?.colorHex ?? '#6C5CE7'),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (data.confirmed.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('Add some transactions to see your reports here.',
                    style: context.text.bodyMedium?.copyWith(color: t.textMid),
                    textAlign: TextAlign.center),
              ),
          ],
        );
      },
    );
  }

  Widget _bigStat(String label, double value, Color color) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(height: 4),
          Text(Money.format(value),
              style: context.text.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _bar(String label, double amount, double fraction, Color color) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('${Money.format(amount)} · ${(fraction * 100).round()}%',
                  style: context.text.bodySmall?.copyWith(color: t.textMid)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Corners.pill),
            child: Stack(
              children: [
                Container(height: 10, color: t.glassFill),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction.clamp(0.03, 1)),
                  duration: Motion.slow,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.accentA.withValues(alpha: 0.2) : t.glassFill,
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(color: selected ? t.accentA.withValues(alpha: 0.5) : t.glassBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? t.accentA : t.textMid, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}
