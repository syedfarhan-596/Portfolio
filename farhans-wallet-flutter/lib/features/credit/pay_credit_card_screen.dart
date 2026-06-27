import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class PayCreditCardScreen extends ConsumerStatefulWidget {
  final int? cardId;
  const PayCreditCardScreen({super.key, this.cardId});

  @override
  ConsumerState<PayCreditCardScreen> createState() => _State();
}

class _State extends ConsumerState<PayCreditCardScreen> {
  int? _cardId;
  int? _fromAccountId;
  final _bank = TextEditingController();
  final _points = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardId = widget.cardId;
  }

  @override
  void dispose() {
    _bank.dispose();
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    if (data == null) return const DetailScaffold(title: 'Pay bill', child: SizedBox());

    final cards = data.accounts.where((a) => a.type == AccountType.creditCard).toList();
    final payFrom = data.accounts.where((a) => a.type != AccountType.creditCard).toList();
    _cardId ??= cards.firstOrNull?.id;
    _fromAccountId ??= payFrom.firstOrNull?.id;
    final outstanding = _cardId == null ? 0.0 : data.balanceOf(_cardId!);

    final bank = double.tryParse(_bank.text) ?? 0;
    final points = double.tryParse(_points.text) ?? 0;

    return DetailScaffold(
      title: 'Pay credit card bill',
      bottomBar: PrimaryButton(
        label: 'Pay bill',
        icon: Icons.check_rounded,
        onPressed: (_cardId != null && (bank + points) > 0)
            ? () {
                ref.read(walletProvider.notifier).payCreditCard(_cardId!, _fromAccountId, bank, points);
                Navigator.pop(context);
              }
            : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.lg),
        children: [
          if (cards.length > 1) ...[
            AppSelectField<Account>(
              label: 'Credit card',
              value: cards.where((a) => a.id == _cardId).firstOrNull,
              options: cards,
              optionLabel: (a) => a.name,
              onChanged: (a) => setState(() => _cardId = a.id),
            ),
            const SizedBox(height: Insets.md),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current outstanding', style: context.text.bodySmall),
                const SizedBox(height: 4),
                Text(Money.format(outstanding),
                    style: context.text.headlineMedium?.copyWith(color: t.accentA)),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Text('Pay from bank / cash', style: context.text.titleSmall),
          const SizedBox(height: Insets.xs),
          AppSelectField<Account>(
            label: 'Account',
            value: payFrom.where((a) => a.id == _fromAccountId).firstOrNull,
            options: payFrom,
            optionLabel: (a) => a.name,
            onChanged: (a) => setState(() => _fromAccountId = a.id),
          ),
          const SizedBox(height: Insets.sm),
          AppTextField(
            label: 'Amount from account (₹)',
            controller: _bank,
            amount: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),
          Text('Pay with reward points', style: context.text.titleSmall),
          const SizedBox(height: Insets.xs),
          AppTextField(
            label: 'Amount paid via points (₹ value)',
            controller: _points,
            amount: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.md),
          if (bank + points > 0)
            Text('Total payment: ${Money.format(bank + points)}',
                style: context.text.bodyMedium?.copyWith(color: t.textMid)),
        ],
      ),
    );
  }
}
