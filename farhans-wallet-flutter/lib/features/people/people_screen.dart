import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import 'add_debt_screen.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(walletProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final people = data.people.where((p) => p.toReceive > 0 || p.toPay > 0).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 120),
          children: [
            Text('People & Lending', style: context.text.headlineMedium),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(child: _SummaryTile('You’ll receive', data.toReceive, t.success)),
                const SizedBox(width: Insets.sm),
                Expanded(child: _SummaryTile('You’ll pay', data.toPay, t.danger)),
              ],
            ),
            const SizedBox(height: Insets.md),
            PrimaryButton(
              label: 'Add lending / borrowing',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddDebtScreen())),
            ),
            const SizedBox(height: Insets.md),
            if (people.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyState(
                  icon: Icons.groups_2_rounded,
                  title: 'No active dues',
                  subtitle: 'Record money you lent or borrowed, or split an expense with a friend.',
                ),
              )
            else
              ...people.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _PersonCard(person: p, data: data),
                  )),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
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
}

class _PersonCard extends ConsumerWidget {
  final PeopleSummary person;
  final WalletData data;
  const _PersonCard({required this.person, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final owesYou = person.net >= 0;
    final unsettled = person.debts.where((d) => !d.settled).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: t.accentGradient,
                  borderRadius: BorderRadius.circular(Corners.sm),
                ),
                child: Text(
                  person.contactName.isEmpty ? '?' : person.contactName.trim()[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.contactName, style: context.text.titleSmall),
                    Text(owesYou ? 'owes you' : 'you owe',
                        style: context.text.bodySmall?.copyWith(color: t.textMid)),
                  ],
                ),
              ),
              Text(Money.format(person.net.abs()),
                  style: context.text.titleMedium
                      ?.copyWith(color: owesYou ? t.success : t.danger)),
            ],
          ),
          if (person.dueAfterSalary) ...[
            const SizedBox(height: Insets.sm),
            const Pill(label: 'Pay after salary', icon: Icons.schedule_rounded),
          ],
          ...unsettled.map((d) => Padding(
                padding: const EdgeInsets.only(top: Insets.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AddDebtScreen(debt: d))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.direction == DebtDirection.iLent ? 'Lent' : 'Borrowed'} · ${Money.format(d.remaining)} left',
                              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (d.note.isNotEmpty)
                              Text(d.note, style: context.text.bodySmall?.copyWith(color: t.textMid)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Pressable(
                      onTap: () => _settle(context, ref, d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
                        decoration: BoxDecoration(
                          color: t.accentA.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(Corners.pill),
                          border: Border.all(color: t.accentA.withValues(alpha: 0.4)),
                        ),
                        child: Text('Settle',
                            style: TextStyle(color: t.accentA, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _settle(BuildContext context, WidgetRef ref, Debt d) {
    final isLent = d.direction == DebtDirection.iLent;
    showGlassSheet(
      context,
      SettleSheet(
        title: isLent ? 'Receive from ${d.contactName}' : 'Pay ${d.contactName}',
        actionLabel: isLent ? 'Receive into account' : 'Pay from account',
        remaining: d.remaining,
        accounts: data.accounts,
        onConfirm: (amount, accountId) {
          ref.read(walletProvider.notifier).recordPayment(d, amount, accountId);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class SettleSheet extends StatefulWidget {
  final String title;
  final String actionLabel;
  final double remaining;
  final List<Account> accounts;
  final void Function(double amount, int? accountId) onConfirm;
  const SettleSheet({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.remaining,
    required this.accounts,
    required this.onConfirm,
  });

  @override
  State<SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<SettleSheet> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.remaining > 0 ? _trim(widget.remaining) : '');
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: context.text.titleMedium),
        const SizedBox(height: 4),
        Text('Remaining: ${Money.format(widget.remaining)}',
            style: context.text.bodySmall?.copyWith(color: t.textMid)),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            _quick('50%', () => _amount.text = _trim(widget.remaining * 0.5)),
            const SizedBox(width: Insets.xs),
            _quick('Full', () => _amount.text = _trim(widget.remaining)),
          ],
        ),
        const SizedBox(height: Insets.sm),
        AppTextField(label: 'Amount (₹)', controller: _amount, amount: true),
        const SizedBox(height: Insets.sm),
        AppSelectField<Account>(
          label: widget.actionLabel,
          value: widget.accounts.where((a) => a.id == _accountId).firstOrNull,
          options: widget.accounts,
          optionLabel: (a) => a.name,
          onChanged: (a) => setState(() => _accountId = a.id),
        ),
        const SizedBox(height: Insets.md),
        PrimaryButton(
          label: 'Confirm',
          onPressed: () {
            final amt = double.tryParse(_amount.text) ?? 0;
            if (amt > 0) widget.onConfirm(amt, _accountId);
          },
        ),
      ],
    );
  }

  Widget _quick(String label, VoidCallback onTap) {
    final t = context.tokens;
    return Pressable(
      onTap: () => setState(onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
        decoration: BoxDecoration(
          color: t.glassFill,
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(color: t.glassBorder),
        ),
        child: Text(label, style: TextStyle(color: t.textHigh, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
