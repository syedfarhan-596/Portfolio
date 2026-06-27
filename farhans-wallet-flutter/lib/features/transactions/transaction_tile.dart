import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/wallet_state.dart';

class TransactionTile extends StatelessWidget {
  final Txn txn;
  final WalletData data;
  final VoidCallback onTap;
  final String? trailingDate;

  const TransactionTile({
    super.key,
    required this.txn,
    required this.data,
    required this.onTap,
    this.trailingDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cat = txn.categoryId != null ? data.categoryById[txn.categoryId] : null;
    final acc = data.accountById[txn.accountId];
    final color = AppIcons.parseColor(cat?.colorHex ?? '#636E72');

    final title = txn.contactName ??
        (txn.merchant.isNotEmpty
            ? txn.merchant
            : (cat?.name ?? _cap(txn.type.name)));

    final subtitleParts = <String>[
      cat?.name ?? _cap(txn.type.name),
      if (acc != null) acc.name,
      if (txn.type == TxnType.transfer && txn.toAccountId != null)
        '→ ${data.accountById[txn.toAccountId]?.name ?? ''}',
    ];

    final (sign, amtColor) = switch (txn.type) {
      TxnType.income => ('+', t.success),
      TxnType.expense => ('-', t.danger),
      TxnType.transfer => ('', t.info),
    };

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Insets.sm),
      radius: Corners.md,
      child: Row(
        children: [
          IconBadge(icon: AppIcons.of(cat?.icon ?? 'category'), color: color),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitleParts.join(' · '),
                    style: context.text.bodySmall?.copyWith(color: t.textMid),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (txn.note.isNotEmpty)
                  Text(txn.note,
                      style: context.text.bodySmall?.copyWith(color: t.textLow),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: Insets.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sign${Money.format(txn.amount)}',
                  style: context.text.titleSmall?.copyWith(color: amtColor)),
              if (trailingDate != null)
                Text(trailingDate!,
                    style: context.text.bodySmall?.copyWith(color: t.textLow, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
