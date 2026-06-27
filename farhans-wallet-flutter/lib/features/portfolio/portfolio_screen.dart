import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import 'add_investment_screen.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final active = data.investments.where((i) => !i.sold).toList();
        final sold = data.investments.where((i) => i.sold).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 120),
          children: [
            Text('Portfolio', style: context.text.headlineMedium),
            const SizedBox(height: Insets.md),
            _Header(data: data),
            const SizedBox(height: Insets.md),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyState(
                  icon: Icons.trending_up_rounded,
                  title: 'No investments yet',
                  subtitle: 'Tap + to add a stock, mutual fund, gold or any asset. The amount is deducted from the account you choose.',
                ),
              )
            else ...[
              const SectionHeader('Holdings'),
              const SizedBox(height: Insets.xs),
              ...active.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: _Holding(inv: i),
                  )),
            ],
            if (sold.isNotEmpty) ...[
              const SizedBox(height: Insets.sm),
              const SectionHeader('Sold / Redeemed'),
              const SizedBox(height: Insets.xs),
              ...sold.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: _Holding(inv: i),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final WalletData data;
  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gain = data.portfolioGain;
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.success, t.accentB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Corners.lg),
        boxShadow: [
          BoxShadow(color: t.accentB.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current value',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 6),
          AnimatedMoney(data.investedValue,
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: Insets.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mini('Invested', Money.format(data.investedCost)),
              _mini(
                'Returns',
                '${gain >= 0 ? '+' : ''}${Money.format(gain)} (${data.portfolioGainPct.toStringAsFixed(1)}%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String l, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      );
}

class _Holding extends StatelessWidget {
  final Investment inv;
  const _Holding({required this.inv});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gain = inv.current - inv.investedAmount;
    return GlassCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => AddInvestmentScreen(investment: inv))),
      padding: const EdgeInsets.all(Insets.md),
      radius: Corners.md,
      child: Row(
        children: [
          IconBadge(icon: Icons.show_chart_rounded, color: t.success),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.name, style: context.text.titleSmall),
                Text(
                  _label(inv.type) + (inv.quantity > 0 ? ' · ${_qty(inv.quantity)} units' : ''),
                  style: context.text.bodySmall?.copyWith(color: t.textMid),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(inv.current), style: context.text.titleSmall),
              if (!inv.sold)
                Text('${gain >= 0 ? '+' : ''}${Money.format(gain)}',
                    style: context.text.bodySmall
                        ?.copyWith(color: gain >= 0 ? t.success : t.danger)),
            ],
          ),
        ],
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
  String _label(InvestmentType ty) {
    final n = ty.name;
    return n[0].toUpperCase() + n.substring(1);
  }
}
