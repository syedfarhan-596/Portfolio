import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/sheets.dart';
import '../../state/wallet_state.dart';
import '../settings/accounts_screen.dart';

/// Lets the user add the banks/cash/cards they actually have, right after
/// install — a fresh DB starts with just a generic "Cash" account.
class OnboardingAccountsPage extends ConsumerWidget {
  const OnboardingAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final accounts = ref.watch(walletProvider).value?.accounts ?? const [];

    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add your accounts', style: context.text.headlineSmall),
          const SizedBox(height: Insets.xs),
          Text(
            'Banks, cash, credit cards — add what you actually use. You can always add '
            'more later from Settings.',
            style: context.text.bodyMedium?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.md),
          Expanded(
            child: ListView(
              children: [
                for (final a in accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: GlassCard(
                      onTap: () => showGlassSheet(context, AccountEditor(account: a, ref: ref)),
                      padding: const EdgeInsets.all(Insets.sm),
                      radius: Corners.md,
                      child: Row(
                        children: [
                          IconBadge(icon: AppIcons.of(a.icon), color: AppIcons.parseColor(a.colorHex)),
                          const SizedBox(width: Insets.sm),
                          Expanded(child: Text(a.name, style: context.text.titleSmall)),
                          Icon(Icons.chevron_right_rounded, color: t.textMid),
                        ],
                      ),
                    ),
                  ),
                SecondaryButton(
                  label: 'Add account',
                  icon: Icons.add_rounded,
                  onPressed: () => showGlassSheet(context, AccountEditor(account: null, ref: ref)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
