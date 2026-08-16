import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import '../credit/pay_credit_card_screen.dart';
import '../settings/account_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(walletProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: t.danger))),
      data: (data) => _Content(data: data),
    );
  }
}

class _Content extends ConsumerWidget {
  final WalletData data;
  const _Content({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final recent = data.confirmed.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, Farhan 👋', style: context.text.bodyMedium?.copyWith(color: t.textMid)),
                  const SizedBox(height: 2),
                  Text('Your money', style: context.text.headlineMedium),
                ],
              ),
            ),
            GlassIconButton(
              icon: Icons.settings_rounded,
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        _BalanceCard(data: data),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'To receive',
                value: Money.format(data.toReceive),
                icon: Icons.south_west_rounded,
                color: t.success,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: _StatTile(
                label: 'To pay',
                value: Money.format(data.toPay),
                icon: Icons.north_east_rounded,
                color: t.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Spent this month',
                value: Money.format(data.monthExpense),
                icon: Icons.trending_down_rounded,
                color: t.danger,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: _StatTile(
                label: 'Income this month',
                value: Money.format(data.monthIncome),
                icon: Icons.trending_up_rounded,
                color: t.success,
              ),
            ),
          ],
        ),
        if (data.pending.isNotEmpty) ...[
          const SizedBox(height: Insets.lg),
          const SectionHeader('Detected from SMS'),
          const SizedBox(height: Insets.xs),
          ...data.pending.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.xs),
                child: _PendingCard(
                  txn: p,
                  onConfirm: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddEditTransactionScreen(txn: p))),
                  onDismiss: () => ref.read(walletProvider.notifier).dismissPending(p),
                ),
              )),
        ],
        const SizedBox(height: Insets.lg),
        const SectionHeader('Accounts'),
        const SizedBox(height: Insets.xs),
        ...data.balances.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: Insets.xs),
              child: _AccountRow(balance: b),
            )),
        const SizedBox(height: Insets.md),
        SectionHeader('Recent activity',
            actionLabel: recent.isEmpty ? null : null, onAction: null),
        const SizedBox(height: Insets.xs),
        if (recent.isEmpty)
          GlassCard(
            child: Text(
              'No transactions yet. Tap + to add one, or scan your SMS inbox in Settings.',
              style: context.text.bodyMedium?.copyWith(color: t.textMid),
            ),
          )
        else
          ...recent.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.xs),
                child: TransactionTile(
                  txn: tx,
                  data: data,
                  trailingDate: Dates.day(tx.dateTime),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddEditTransactionScreen(txn: tx))),
                ),
              )),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletData data;
  const _BalanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.accentA, t.accentB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Corners.lg),
        boxShadow: [
          BoxShadow(color: t.accentB.withValues(alpha: 0.4), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available balance',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 6),
          AnimatedMoney(
            data.liquidTotal,
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Mini(label: 'Net worth', value: Money.short(data.netWorth)),
              _Mini(label: 'Invested', value: Money.short(data.investedValue)),
              _Mini(label: 'Card due', value: Money.short(data.creditOutstanding)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

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

class _AccountRow extends StatelessWidget {
  final AccountBalance balance;
  const _AccountRow({required this.balance});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final a = balance.account;
    final isCard = a.type == AccountType.creditCard;
    final shown = isCard ? -balance.balance : balance.balance;
    return GlassCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => AccountDetailScreen(accountId: a.id!))),
      padding: const EdgeInsets.all(Insets.sm),
      radius: Corners.md,
      child: Row(
        children: [
          IconBadge(icon: AppIcons.of(a.icon), color: AppIcons.parseColor(a.colorHex)),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: context.text.titleSmall),
                Text(isCard ? 'Outstanding' : 'Balance',
                    style: context.text.bodySmall?.copyWith(color: t.textMid)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(shown),
                  style: context.text.titleSmall?.copyWith(
                      color: isCard && balance.balance > 0 ? t.danger : t.textHigh)),
              if (isCard)
                Pressable(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PayCreditCardScreen(cardId: a.id))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Pay bill',
                        style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Txn txn;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _PendingCard({required this.txn, required this.onConfirm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isIncome = txn.type == TxnType.income;
    return GlassCard(
      onTap: onConfirm,
      strong: true,
      padding: const EdgeInsets.all(Insets.sm),
      radius: Corners.md,
      child: Row(
        children: [
          IconBadge(
              icon: Icons.sms_rounded, color: t.accentA, size: 42),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.merchant.isNotEmpty ? txn.merchant : 'Unknown',
                    style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${Dates.dateTime(txn.dateTime)} · tap to categorize',
                    style: context.text.bodySmall?.copyWith(color: t.textMid),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('${isIncome ? '+' : '-'}${Money.short(txn.amount)}',
              style: context.text.titleSmall
                  ?.copyWith(color: isIncome ? t.success : t.danger)),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: t.textMid, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
