import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';
  TxnType? _filter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(walletProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final filtered = data.confirmed.where((tx) {
          if (_filter != null && tx.type != _filter) return false;
          if (_query.isEmpty) return true;
          final hay = [
            tx.merchant,
            tx.note,
            tx.contactName ?? '',
            tx.categoryId != null ? data.categoryById[tx.categoryId]?.name ?? '' : '',
          ].join(' ').toLowerCase();
          return hay.contains(_query.toLowerCase());
        }).toList();

        // group by date
        final groups = <String, List<Txn>>{};
        for (final tx in filtered) {
          groups.putIfAbsent(Dates.date(tx.dateTime), () => []).add(tx);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 120),
          children: [
            Text('Activity', style: context.text.headlineMedium),
            const SizedBox(height: Insets.md),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 4),
              radius: Corners.md,
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: t.textMid),
                  const SizedBox(width: Insets.xs),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: context.text.bodyLarge,
                      cursorColor: t.accentA,
                      decoration: InputDecoration(
                        hintText: 'Search merchant, note, person…',
                        hintStyle: TextStyle(color: t.textLow),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('All', _filter == null, () => setState(() => _filter = null)),
                  _chip('Expense', _filter == TxnType.expense,
                      () => setState(() => _filter = TxnType.expense)),
                  _chip('Income', _filter == TxnType.income,
                      () => setState(() => _filter = TxnType.income)),
                  _chip('Transfer', _filter == TxnType.transfer,
                      () => setState(() => _filter = TxnType.transfer)),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Nothing here yet',
                  subtitle: 'Add a transaction with +, or import from SMS in Settings.',
                ),
              )
            else
              ...groups.entries.expand((g) {
                final dayTotal = g.value.fold<double>(
                    0, (s, tx) => s + (tx.type == TxnType.income ? tx.amount : -tx.amount));
                return [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, Insets.sm, 4, Insets.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g.key,
                            style: context.text.labelMedium?.copyWith(color: t.textMid)),
                        Text(Money.format(dayTotal),
                            style: context.text.labelMedium?.copyWith(color: t.textMid)),
                      ],
                    ),
                  ),
                  ...g.value.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: Insets.xs),
                        child: TransactionTile(
                          txn: tx,
                          data: data,
                          trailingDate: Dates.time(tx.dateTime),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => AddEditTransactionScreen(txn: tx))),
                        ),
                      )),
                ];
              }),
          ],
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: Insets.xs),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? t.accentA.withValues(alpha: 0.2) : t.glassFill,
            borderRadius: BorderRadius.circular(Corners.pill),
            border: Border.all(
                color: selected ? t.accentA.withValues(alpha: 0.5) : t.glassBorder),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? t.accentA : t.textMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
