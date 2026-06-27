import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import '../people/people_screen.dart' show SettleSheet;

class AddInvestmentScreen extends ConsumerStatefulWidget {
  final Investment? investment;
  const AddInvestmentScreen({super.key, this.investment});

  @override
  ConsumerState<AddInvestmentScreen> createState() => _State();
}

class _State extends ConsumerState<AddInvestmentScreen> {
  final _name = TextEditingController();
  late InvestmentType _type;
  final _invested = TextEditingController();
  final _quantity = TextEditingController();
  final _current = TextEditingController();
  final _note = TextEditingController();
  int? _accountId;
  late DateTime _dt;

  bool get _editing => widget.investment != null;

  @override
  void initState() {
    super.initState();
    final i = widget.investment;
    _type = i?.type ?? InvestmentType.stock;
    if (i != null) {
      _name.text = i.name;
      _invested.text = _trim(i.investedAmount);
      if (i.quantity > 0) _quantity.text = _trim(i.quantity);
      if (i.currentValue != null) _current.text = _trim(i.currentValue!);
      _note.text = i.note;
      _accountId = i.accountId;
      _dt = DateTime.fromMillisecondsSinceEpoch(i.createdAt);
    } else {
      _dt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _quantity.dispose();
    _current.dispose();
    _note.dispose();
    super.dispose();
  }

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  String _label(InvestmentType ty) {
    final n = ty.name;
    return (n[0].toUpperCase() + n.substring(1)).replaceAll('Fund', ' Fund');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(walletProvider).value;
    if (data == null) return const DetailScaffold(title: 'Investment', child: SizedBox());
    final accounts = data.accounts;
    _accountId ??= accounts.firstOrNull?.id;

    return DetailScaffold(
      title: _editing ? 'Edit investment' : 'Add investment',
      trailing: _editing
          ? GlassIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                ref.read(walletProvider.notifier).deleteInvestment(widget.investment!);
                Navigator.pop(context);
              })
          : null,
      bottomBar: PrimaryButton(
        label: _editing ? 'Update' : 'Add investment',
        icon: Icons.check_rounded,
        onPressed: () => _save(),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.lg),
        children: [
          AppTextField(label: 'Name (e.g. Reliance, Nifty 50)', controller: _name),
          const SizedBox(height: Insets.md),
          AppSelectField<InvestmentType>(
            label: 'Type',
            value: _type,
            options: InvestmentType.values,
            optionLabel: _label,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Amount invested (₹)', controller: _invested, amount: true),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Quantity / units (optional)', controller: _quantity, amount: true),
          const SizedBox(height: Insets.md),
          AppTextField(label: 'Current value (optional, for returns)', controller: _current, amount: true),
          const SizedBox(height: Insets.md),
          if (!_editing)
            AppSelectField<Account>(
              label: 'Pay from account',
              value: accounts.where((a) => a.id == _accountId).firstOrNull,
              options: accounts,
              optionLabel: (a) => a.name,
              onChanged: (a) => setState(() => _accountId = a.id),
            ),
          if (!_editing) const SizedBox(height: Insets.md),
          AppTextField(label: 'Note (optional)', controller: _note, maxLines: 2),
          if (_editing && !widget.investment!.sold) ...[
            const SizedBox(height: Insets.md),
            SecondaryButton(
              label: 'Sell / Redeem',
              icon: Icons.sell_rounded,
              onPressed: () => _sell(accounts),
            ),
          ],
        ],
      ),
    );
  }

  void _sell(List<Account> accounts) {
    final inv = widget.investment!;
    showGlassSheet(
      context,
      SettleSheet(
        title: 'Sell ${inv.name}',
        actionLabel: 'Credit proceeds to',
        remaining: inv.current,
        accounts: accounts,
        onConfirm: (amount, accountId) {
          ref.read(walletProvider.notifier).sellInvestment(inv, amount, accountId);
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close screen
        },
      ),
    );
  }

  void _save() {
    final invested = double.tryParse(_invested.text) ?? 0;
    if (invested <= 0 || _name.text.trim().isEmpty) return;
    final qty = double.tryParse(_quantity.text) ?? 0;
    final cur = double.tryParse(_current.text);
    final notifier = ref.read(walletProvider.notifier);
    if (_editing) {
      notifier.updateInvestment(widget.investment!.copyWith(
        name: _name.text.trim(),
        type: _type,
        quantity: qty,
        investedAmount: invested,
        currentValue: cur,
        note: _note.text,
      ));
    } else {
      notifier.buyInvestment(Investment(
        name: _name.text.trim(),
        type: _type,
        quantity: qty,
        investedAmount: invested,
        currentValue: cur,
        accountId: _accountId,
        createdAt: _dt.millisecondsSinceEpoch,
        note: _note.text,
      ));
    }
    Navigator.pop(context);
  }
}
