import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/sheets.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(walletProvider).value;
    final balances = data?.balances ?? [];

    return DetailScaffold(
      title: 'Accounts',
      trailing: GlassIconButton(
        icon: Icons.add_rounded,
        onPressed: () => _edit(context, ref, null),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.xs, Insets.lg, Insets.xl),
        children: [
          for (final b in balances)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.xs),
              child: GlassCard(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AccountDetailScreen(accountId: b.account.id!))),
                padding: const EdgeInsets.all(Insets.sm),
                radius: Corners.md,
                child: Row(
                  children: [
                    IconBadge(icon: AppIcons.of(b.account.icon), color: AppIcons.parseColor(b.account.colorHex)),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.account.name, style: context.text.titleSmall),
                          Text(_typeLabel(b.account.type),
                              style: context.text.bodySmall?.copyWith(color: t.textMid)),
                        ],
                      ),
                    ),
                    Text(
                      Money.format(b.account.type == AccountType.creditCard ? -b.balance : b.balance),
                      style: context.text.titleSmall?.copyWith(
                          color: b.account.type == AccountType.creditCard && b.balance > 0
                              ? t.danger
                              : t.textHigh),
                    ),
                    IconButton(
                      onPressed: () => _edit(context, ref, b.account),
                      icon: Icon(Icons.edit_rounded, color: t.textMid, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _typeLabel(AccountType ty) => switch (ty) {
        AccountType.bank => 'Bank',
        AccountType.cash => 'Cash',
        AccountType.creditCard => 'Credit card',
        AccountType.wallet => 'Wallet',
      };

  void _edit(BuildContext context, WidgetRef ref, Account? account) {
    showGlassSheet(context, AccountEditor(account: account, ref: ref));
  }
}

class AccountEditor extends StatefulWidget {
  final Account? account;
  final WidgetRef ref;
  const AccountEditor({super.key, required this.account, required this.ref});

  @override
  State<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<AccountEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.account?.name ?? '');
  late final TextEditingController _opening = TextEditingController(
      text: widget.account == null ? '' : _trim(widget.account!.openingBalance));
  late AccountType _type = widget.account?.type ?? AccountType.bank;
  late String _color = widget.account?.colorHex ?? AppIcons.palette.first;
  late String _icon = widget.account?.icon ?? 'account_balance';
  late bool _includeInTotal = widget.account?.includeInTotal ?? true;

  String _trim(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final editing = widget.account != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(editing ? 'Edit account' : 'New account', style: context.text.titleMedium),
        const SizedBox(height: Insets.md),
        AppTextField(label: 'Name', controller: _name),
        const SizedBox(height: Insets.sm),
        AppSelectField<AccountType>(
          label: 'Type',
          value: _type,
          options: AccountType.values,
          optionLabel: (ty) => switch (ty) {
            AccountType.bank => 'Bank',
            AccountType.cash => 'Cash',
            AccountType.creditCard => 'Credit card',
            AccountType.wallet => 'Wallet',
          },
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: Insets.sm),
        AppTextField(
          label: _type == AccountType.creditCard ? 'Current outstanding owed (₹)' : 'Opening balance (₹)',
          controller: _opening,
          amount: true,
        ),
        const SizedBox(height: Insets.md),
        Text('Color', style: context.text.labelMedium),
        const SizedBox(height: Insets.xs),
        ColorPickerRow(selected: _color, onSelect: (c) => setState(() => _color = c)),
        const SizedBox(height: Insets.md),
        Text('Icon', style: context.text.labelMedium),
        const SizedBox(height: Insets.xs),
        IconPickerRow(
            selected: _icon,
            tint: AppIcons.parseColor(_color),
            onSelect: (i) => setState(() => _icon = i)),
        const SizedBox(height: Insets.md),
        GlassCard(
          radius: Corners.sm,
          child: Row(
            children: [
              Expanded(child: Text('Include in available balance', style: context.text.bodyLarge)),
              Switch(
                value: _includeInTotal,
                activeThumbColor: t.accentA,
                onChanged: (v) => setState(() => _includeInTotal = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            if (editing)
              Expanded(
                child: SecondaryButton(
                  label: 'Delete',
                  onPressed: () {
                    widget.ref.read(walletProvider.notifier).deleteAccount(widget.account!);
                    Navigator.pop(context);
                  },
                ),
              ),
            if (editing) const SizedBox(width: Insets.sm),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Save',
                onPressed: () {
                  if (_name.text.trim().isEmpty) return;
                  final base = widget.account ?? Account(name: _name.text, type: _type);
                  widget.ref.read(walletProvider.notifier).saveAccount(base.copyWith(
                        name: _name.text.trim(),
                        type: _type,
                        openingBalance: double.tryParse(_opening.text) ?? 0,
                        colorHex: _color,
                        icon: _icon,
                        includeInTotal: _includeInTotal,
                      ));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
