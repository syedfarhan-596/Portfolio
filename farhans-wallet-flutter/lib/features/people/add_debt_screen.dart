import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/segmented.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final Debt? debt;
  const AddDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddDebtScreen> createState() => _State();
}

class _State extends ConsumerState<AddDebtScreen> {
  late DebtDirection _dir;
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _payment = TextEditingController();
  late DateTime _dt;
  String? _contactKey;
  bool _dueAfterSalary = false;
  int? _accountId;
  int? _payAccountId;

  bool get _editing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _dir = d?.direction ?? DebtDirection.iLent;
    if (d != null) {
      _amount.text = _trim(d.amount);
      _name.text = d.contactName;
      _note.text = d.note;
      _contactKey = d.contactKey;
      _dt = DateTime.fromMillisecondsSinceEpoch(d.createdAt);
      _dueAfterSalary = d.dueAfterSalary;
      _accountId = d.accountId;
    } else {
      _dt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _note.dispose();
    _payment.dispose();
    super.dispose();
  }

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  Future<void> _pickContact() async {
    final picked = await ref.read(contactsServiceProvider).pick();
    if (picked != null) {
      setState(() {
        _name.text = picked.name;
        _contactKey = picked.key;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    if (data == null) return const DetailScaffold(title: 'Lending', child: SizedBox());
    final accounts = data.accounts;
    _accountId ??= accounts.firstOrNull?.id;
    _payAccountId ??= accounts.firstOrNull?.id;

    return DetailScaffold(
      title: _editing ? 'Edit entry' : 'Add lending / borrowing',
      trailing: _editing
          ? GlassIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                ref.read(walletProvider.notifier).deleteDebt(widget.debt!);
                Navigator.pop(context);
              })
          : null,
      bottomBar: PrimaryButton(
        label: _editing ? 'Update' : 'Save',
        icon: Icons.check_rounded,
        onPressed: () => _save(accounts),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.lg),
        children: [
          GlassSegmented<DebtDirection>(
            values: const [DebtDirection.iLent, DebtDirection.iBorrowed],
            selected: _dir,
            label: (v) => v == DebtDirection.iLent ? 'I lent' : 'I borrowed',
            onChanged: (v) => setState(() => _dir = v),
          ),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Amount (₹)', controller: _amount, amount: true),
          const SizedBox(height: Insets.md),
          SecondaryButton(
            label: _name.text.isEmpty ? 'Pick person from contacts' : 'Change person',
            icon: Icons.person_add_alt_rounded,
            onPressed: _pickContact,
          ),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Name', controller: _name),
          const SizedBox(height: Insets.md),
          _DateField(dt: _dt, onTap: _pickDate),
          const SizedBox(height: Insets.md),
          if (!_editing) ...[
            AppSelectField<Account>(
              label: _dir == DebtDirection.iLent
                  ? 'Money goes out of (account)'
                  : 'Money received into (account)',
              value: accounts.where((a) => a.id == _accountId).firstOrNull,
              options: accounts,
              optionLabel: (a) => a.name,
              onChanged: (a) => setState(() => _accountId = a.id),
            ),
            const SizedBox(height: 6),
            Text(
              _dir == DebtDirection.iLent
                  ? 'This amount will be deducted from the selected account now.'
                  : 'This amount will be added to the selected account now.',
              style: context.text.bodySmall?.copyWith(color: t.textMid),
            ),
            const SizedBox(height: Insets.md),
          ],
          AppTextField(label: 'What is it for? (note)', controller: _note, maxLines: 2),
          const SizedBox(height: Insets.md),
          GlassCard(
            radius: Corners.sm,
            child: Row(
              children: [
                Expanded(child: Text('Remind / pay after salary', style: context.text.bodyLarge)),
                Switch(
                  value: _dueAfterSalary,
                  activeThumbColor: t.accentA,
                  onChanged: (v) => setState(() => _dueAfterSalary = v),
                ),
              ],
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: Insets.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Paid so far: ${Money.format(widget.debt!.paidAmount)} of ${Money.format(widget.debt!.amount)}',
                      style: context.text.bodyMedium?.copyWith(color: t.textMid)),
                  const SizedBox(height: Insets.sm),
                  AppSelectField<Account>(
                    label: _dir == DebtDirection.iLent ? 'Receive into account' : 'Pay from account',
                    value: accounts.where((a) => a.id == _payAccountId).firstOrNull,
                    options: accounts,
                    optionLabel: (a) => a.name,
                    onChanged: (a) => setState(() => _payAccountId = a.id),
                  ),
                  const SizedBox(height: Insets.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: AppTextField(label: 'Record payment', controller: _payment, amount: true)),
                      const SizedBox(width: Insets.sm),
                      PrimaryButton(
                        label: 'Add',
                        expand: false,
                        onPressed: () {
                          final p = double.tryParse(_payment.text) ?? 0;
                          if (p > 0) {
                            ref.read(walletProvider.notifier).recordPayment(widget.debt!, p, _payAccountId);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _dt, firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (d != null) setState(() => _dt = DateTime(d.year, d.month, d.day, _dt.hour, _dt.minute));
  }

  void _save(List<Account> accounts) {
    final amt = double.tryParse(_amount.text) ?? 0;
    if (amt <= 0) return;
    final name = _name.text.trim().isEmpty ? 'Someone' : _name.text.trim();
    final notifier = ref.read(walletProvider.notifier);
    if (!_editing) {
      notifier.addLending(
        Debt(
          contactName: name,
          contactKey: _contactKey,
          direction: _dir,
          amount: amt,
          note: _note.text,
          createdAt: _dt.millisecondsSinceEpoch,
          dueAfterSalary: _dueAfterSalary,
        ),
        _accountId,
      );
    } else {
      notifier.saveDebt(widget.debt!.copyWith(
        contactName: name,
        contactKey: _contactKey,
        direction: _dir,
        amount: amt,
        note: _note.text,
        createdAt: _dt.millisecondsSinceEpoch,
        dueAfterSalary: _dueAfterSalary,
      ));
    }
    Navigator.pop(context);
  }
}

class _DateField extends StatelessWidget {
  final DateTime dt;
  final VoidCallback onTap;
  const _DateField({required this.dt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      onTap: onTap,
      radius: Corners.sm,
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.md),
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: t.textMid),
          const SizedBox(width: Insets.sm),
          Expanded(
              child: Text(Dates.date(dt.millisecondsSinceEpoch),
                  style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
          Icon(Icons.expand_more_rounded, color: t.textMid),
        ],
      ),
    );
  }
}
