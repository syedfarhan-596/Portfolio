import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/wallet_state.dart';
import '../shell/home_shell.dart';
import 'app_lock_screen.dart';

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
