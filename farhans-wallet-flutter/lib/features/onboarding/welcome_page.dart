import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(gradient: t.accentGradient, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: Insets.lg),
          Text('Welcome to Pocket Flow', style: context.text.headlineMedium),
          const SizedBox(height: Insets.xs),
          Text(
            'A money tracker that lives entirely on your phone — no account, no cloud, no ads.',
            style: context.text.bodyLarge?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.xl),
          const _Bullet(
            icon: Icons.sms_rounded,
            text: 'Reads your bank & UPI SMS to log transactions automatically',
          ),
          const _Bullet(
            icon: Icons.lock_rounded,
            text: 'Everything stays on your device — nothing is ever uploaded anywhere',
          ),
          const _Bullet(
            icon: Icons.insights_rounded,
            text: 'Budgets, savings goals, and spending insights built right in',
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: t.accentA, size: 36),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text, style: context.text.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
