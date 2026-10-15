import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/bits.dart';
import '../../core/widgets/buttons.dart';
import '../../state/wallet_state.dart';
import '../lock/pin_setup_screen.dart';

class OnboardingSecurityPage extends ConsumerStatefulWidget {
  const OnboardingSecurityPage({super.key});

  @override
  ConsumerState<OnboardingSecurityPage> createState() => _OnboardingSecurityPageState();
}

class _OnboardingSecurityPageState extends ConsumerState<OnboardingSecurityPage> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final locked = ref.read(prefsProvider).appLockEnabled;

    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.shield_rounded, color: t.success, size: 56),
          const SizedBox(height: Insets.lg),
          Text('Keep your data private', style: context.text.headlineSmall),
          const SizedBox(height: Insets.xs),
          Text(
            'Set a PIN (with optional fingerprint/face unlock) so only you can open the '
            'app. Optional, but recommended since this is your financial data.',
            style: context.text.bodyMedium?.copyWith(color: t.textMid),
          ),
          const SizedBox(height: Insets.lg),
          PrimaryButton(
            label: locked ? 'PIN is set ✓' : 'Set up PIN',
            icon: Icons.pin_rounded,
            onPressed: () async {
              await Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
