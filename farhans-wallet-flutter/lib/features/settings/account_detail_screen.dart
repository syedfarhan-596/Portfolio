import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transaction_tile.dart';
import 'accounts_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  final int accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    if (data == null) return const DetailScaffold(title: 'Account', child: SizedBox());

    final balance = data.balances.where((b) => b.account.id == accountId).firstOrNull;
    if (balance == null) return const DetailScaffold(title: 'Account', child: SizedBox());

    final account = balance.account;
    final isCard = account.type == AccountType.creditCard;
    final accentColor = AppIcons.parseColor(account.colorHex);

    final accountTxns = data.confirmed
        .where((tx) => tx.accountId == accountId || tx.toAccountId == accountId)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final nowMonth = Dates.monthKeyNow();
    final monthTxns = accountTxns.where(
        (tx) => tx.accountId == accountId && Dates.monthKey(tx.dateTime) == nowMonth);
    final monthOut = monthTxns
        .where((tx) => tx.type == TxnType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);
    final monthIn = monthTxns
        .where((tx) => tx.type == TxnType.income)
        .fold(0.0, (s, tx) => s + tx.amount);

    return DetailScaffold(
      title: account.name,
      trailing: GlassIconButton(
        icon: Icons.edit_rounded,
        onPressed: () async {
          await showGlassSheet(context, AccountEditor(account: account, ref: ref));
          if (!context.mounted) return;
          final stillExists =
              ref.read(walletProvider).value?.accounts.any((a) => a.id == accountId) ?? false;
          if (!stillExists) Navigator.pop(context);
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(Insets.lg),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(Corners.lg),
              boxShadow: [
                BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(icon: AppIcons.of(account.icon), color: Colors.white),
                    const SizedBox(width: Insets.sm),
                    Text(
                      isCard ? 'Outstanding' : 'Balance',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                Text(
                  Money.format(isCard ? -balance.balance : balance.balance),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'This month spent',
                  value: Money.format(monthOut),
                  icon: Icons.trending_down_rounded,
                  color: t.danger,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: _MiniStat(
                  label: isCard ? 'This month paid in' : 'This month in',
                  value: Money.format(monthIn),
                  icon: Icons.trending_up_rounded,
                  color: t.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          SectionHeader('Transactions (${accountTxns.length})'),
          const SizedBox(height: Insets.xs),
          if (accountTxns.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No transactions yet',
              subtitle: 'Transactions posted to this account will show up here.',
            )
          else
            ...accountTxns.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.xs),
                  child: TransactionTile(
                    txn: tx,
                    data: data,
                    trailingDate: Dates.day(tx.dateTime),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => AddEditTransactionScreen(txn: tx))),
                  ),
                )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          const SizedBox(height: Insets.sm),
          Text(label, style: context.text.bodySmall?.copyWith(color: t.textMid)),
          const SizedBox(height: 2),
          Text(value, style: context.text.titleMedium),
        ],
      ),
    );
  }
}
