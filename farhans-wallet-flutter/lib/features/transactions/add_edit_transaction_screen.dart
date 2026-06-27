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

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Txn? txn;
  const AddEditTransactionScreen({super.key, this.txn});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _State();
}

class _State extends ConsumerState<AddEditTransactionScreen> {
  late TxnType _type;
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  late DateTime _dt;
  String? _contactName;
  String? _contactKey;
  bool _split = false;
  final _splitAmount = TextEditingController();

  bool get _editing => widget.txn != null;

  @override
  void initState() {
    super.initState();
    final t = widget.txn;
    _type = t?.type ?? TxnType.expense;
    if (t != null) {
      _amount.text = _trim(t.amount);
      _merchant.text = t.merchant;
      _note.text = t.note;
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      _dt = DateTime.fromMillisecondsSinceEpoch(t.dateTime);
      _contactName = t.contactName;
      _contactKey = t.contactKey;
    } else {
      _dt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    _splitAmount.dispose();
    super.dispose();
  }

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  Future<void> _pickContact() async {
    final picked = await ref.read(contactsServiceProvider).pick();
    if (picked != null) {
      setState(() {
        _contactName = picked.name;
        _contactKey = picked.key;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dt,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (!mounted) return;
    final tm = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_dt));
    setState(() {
      _dt = DateTime(d.year, d.month, d.day, tm?.hour ?? _dt.hour, tm?.minute ?? _dt.minute);
    });
  }

  void _save(WalletData data) {
    final amt = double.tryParse(_amount.text) ?? 0;
    if (amt <= 0) return;
    final accId = _accountId ?? data.accounts.firstOrNull?.id;
    if (accId == null) return;
    if (_type == TxnType.transfer && (_toAccountId == null || _toAccountId == accId)) return;

    final base = widget.txn ?? Txn(type: _type, amount: amt, accountId: accId, dateTime: _dt.millisecondsSinceEpoch);
    final txn = base.copyWith(
      type: _type,
      amount: amt,
      accountId: accId,
      toAccountId: _type == TxnType.transfer ? _toAccountId : null,
      categoryId: _type == TxnType.transfer ? null : _categoryId,
      note: _note.text,
      merchant: _merchant.text,
      dateTime: _dt.millisecondsSinceEpoch,
      status: TxnStatus.confirmed,
      contactName: _contactName,
      contactKey: _contactKey,
    );
    final notifier = ref.read(walletProvider.notifier);
    notifier.saveTxn(txn);

    if (_split && _type == TxnType.expense) {
      final owe = double.tryParse(_splitAmount.text) ?? 0;
      if (owe > 0) {
        notifier.saveDebt(Debt(
          contactName: _contactName ?? 'Someone',
          contactKey: _contactKey,
          direction: DebtDirection.iLent,
          amount: owe,
          note: _note.text.isEmpty ? _merchant.text : _note.text,
          createdAt: _dt.millisecondsSinceEpoch,
          accountId: accId,
        ));
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    if (data == null) {
      return const DetailScaffold(title: 'Transaction', child: SizedBox());
    }
    final accounts = data.accounts;
    final cats = data.categoriesOfType(_type);
    final selectedAcc = accounts.where((a) => a.id == _accountId).firstOrNull ?? accounts.firstOrNull;
    final selectedCat = cats.where((c) => c.id == _categoryId).firstOrNull ?? cats.firstOrNull;

    return DetailScaffold(
      title: _editing ? 'Edit transaction' : 'Add transaction',
      trailing: _editing
          ? GlassIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                ref.read(walletProvider.notifier).deleteTxn(widget.txn!);
                Navigator.pop(context);
              },
            )
          : null,
      bottomBar: PrimaryButton(
        label: _editing ? 'Update' : 'Save transaction',
        icon: Icons.check_rounded,
        onPressed: () => _save(data),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.lg),
        children: [
          GlassSegmented<TxnType>(
            values: const [TxnType.expense, TxnType.income, TxnType.transfer],
            selected: _type,
            label: (v) => _cap(v.name),
            onChanged: (v) => setState(() {
              _type = v;
              _categoryId = null;
            }),
          ),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Amount (₹)', controller: _amount, amount: true),
          const SizedBox(height: Insets.md),
          AppSelectField<Account>(
            label: _type == TxnType.transfer ? 'From account' : 'Account',
            value: selectedAcc,
            options: accounts,
            optionLabel: (a) => a.name,
            onChanged: (a) => setState(() => _accountId = a.id),
          ),
          const SizedBox(height: Insets.md),
          if (_type == TxnType.transfer)
            AppSelectField<Account>(
              label: 'To account',
              value: accounts.where((a) => a.id == _toAccountId).firstOrNull,
              options: accounts.where((a) => a.id != selectedAcc?.id).toList(),
              optionLabel: (a) => a.name,
              onChanged: (a) => setState(() => _toAccountId = a.id),
            )
          else
            AppSelectField<Category>(
              label: 'Category',
              value: selectedCat,
              options: cats,
              optionLabel: (c) => c.name,
              onChanged: (c) => setState(() => _categoryId = c.id),
            ),
          const SizedBox(height: Insets.md),
          _DateField(dt: _dt, onTap: _pickDateTime),
          const SizedBox(height: Insets.md),
          if (_type != TxnType.transfer) ...[
            AppTextField(label: 'Merchant / paid to', controller: _merchant),
            const SizedBox(height: Insets.md),
            _ContactField(
              name: _contactName,
              onPick: _pickContact,
              onClear: () => setState(() {
                _contactName = null;
                _contactKey = null;
              }),
            ),
            const SizedBox(height: Insets.md),
          ],
          AppTextField(label: 'Note (optional)', controller: _note, maxLines: 2),
          if (_type == TxnType.expense) ...[
            const SizedBox(height: Insets.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Someone owes me part of this',
                                style: context.text.titleSmall),
                            Text('Track a friend’s share / money you lent',
                                style: context.text.bodySmall?.copyWith(color: t.textMid)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _split,
                        activeThumbColor: t.accentA,
                        onChanged: (v) => setState(() => _split = v),
                      ),
                    ],
                  ),
                  if (_split) ...[
                    const SizedBox(height: Insets.sm),
                    AppTextField(label: 'Amount they owe me (₹)', controller: _splitAmount, amount: true),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);
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
          Icon(Icons.event_rounded, color: t.textMid, size: IconSizes.md),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(Dates.dateTime(dt.millisecondsSinceEpoch),
                style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.expand_more_rounded, color: t.textMid),
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  final String? name;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _ContactField({required this.name, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (name == null) {
      return SecondaryButton(
        label: 'Attach a person (friend / contact)',
        icon: Icons.person_add_alt_rounded,
        onPressed: onPick,
      );
    }
    return GlassCard(
      radius: Corners.sm,
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
      child: Row(
        children: [
          Icon(Icons.person_rounded, color: t.accentA),
          const SizedBox(width: Insets.sm),
          Expanded(child: Text(name!, style: context.text.titleSmall)),
          GestureDetector(onTap: onPick, child: Icon(Icons.edit_rounded, color: t.textMid, size: 20)),
          const SizedBox(width: Insets.sm),
          GestureDetector(onTap: onClear, child: Icon(Icons.close_rounded, color: t.textMid, size: 20)),
        ],
      ),
    );
  }
}
