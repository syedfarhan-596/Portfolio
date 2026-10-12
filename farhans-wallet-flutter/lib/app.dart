import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/lock/app_lock_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/wallet_state.dart';

class FarhansWalletApp extends ConsumerWidget {
  const FarhansWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Pocket Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      builder: (context, child) => AppBackground(child: child ?? const SizedBox()),
      home: const LockGate(),
    );
  }
}

/// Gates HomeShell behind the PIN/biometric lock screen when enabled —
/// unlocked once per cold start, and again whenever the app is actually
/// backgrounded (not just momentarily inactive, e.g. a permission dialog).
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool _unlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = !ref.read(prefsProvider).appLockEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    if (!ref.read(prefsProvider).appLockEnabled) return;
    setState(() => _unlocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return AppLockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const HomeShell();
  }
}
