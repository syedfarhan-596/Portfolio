import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/glass.dart';
import '../../state/wallet_state.dart';

/// Soft-asks for the two optional permissions the app can use — explaining
/// why before the OS dialog appears, rather than surprising the user with it.
class OnboardingPermissionsPage extends ConsumerStatefulWidget {
  const OnboardingPermissionsPage({super.key});

  @override
  ConsumerState<OnboardingPermissionsPage> createState() => _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends ConsumerState<OnboardingPermissionsPage> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final prefs = ref.read(prefsProvider);

    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Let Pocket Flow help automatically', style: context.text.headlineSmall),
          const SizedBox(height: Insets.xs),
          Text(
            'Both are optional and can be changed anytime in Settings.',
            style: context.text.bodyMedium?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(icon: Icons.sms_rounded, color: t.success),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-capture from SMS', style: context.text.titleSmall),
                          Text(
                            'Reads bank/UPI texts on your phone to log transactions — '
                            'never leaves your device.',
                            style: context.text.bodySmall?.copyWith(color: t.textMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                SecondaryButton(
                  label: prefs.smsPermGranted ? 'SMS capture enabled ✓' : 'Enable SMS capture',
                  icon: Icons.sms_rounded,
                  onPressed: () async {
                    await ref.read(walletProvider.notifier).ensureSmsSetup();
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(icon: Icons.notifications_active_rounded, color: t.accentA),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reminders', style: context.text.titleSmall),
                          Text(
                            'A nightly nudge to log expenses, plus card due-date alerts.',
                            style: context.text.bodySmall?.copyWith(color: t.textMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                SecondaryButton(
                  label: 'Enable reminders',
                  icon: Icons.notifications_active_rounded,
                  onPressed: () async {
                    await ref.read(notificationProvider).requestPermission();
                    await ref
                        .read(notificationProvider)
                        .scheduleDaily(prefs.reminderHour, prefs.reminderMinute);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
