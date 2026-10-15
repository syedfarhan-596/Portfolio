import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/lock/lock_gate.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'state/wallet_state.dart';

class FarhansWalletApp extends ConsumerWidget {
  const FarhansWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final onboarded = ref.read(prefsProvider).onboardingComplete;
    return MaterialApp(
      title: 'Pocket Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      builder: (context, child) => AppBackground(child: child ?? const SizedBox()),
      home: onboarded ? const LockGate() : const OnboardingFlow(),
    );
  }
}
