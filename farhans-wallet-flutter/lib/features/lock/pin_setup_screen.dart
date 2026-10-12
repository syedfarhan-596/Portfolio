import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../state/wallet_state.dart';
import 'app_lock_screen.dart';

/// Create (or change) the app-lock PIN: enter it once, then confirm.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _first = '';
  String _entered = '';
  bool _confirming = false;
  bool _error = false;

  void _tap(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = false;
    });
    if (_entered.length == 4) _submit();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _submit() {
    if (!_confirming) {
      setState(() {
        _first = _entered;
        _entered = '';
        _confirming = true;
      });
      return;
    }
    if (_entered == _first) {
      final prefs = ref.read(prefsProvider);
      ref.read(lockServiceProvider).setPin(prefs, _entered);
      prefs.appLockEnabled = true;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = true;
        _entered = '';
        _first = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DetailScaffold(
      title: 'Set up PIN',
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(_confirming ? 'Confirm PIN' : 'Choose a 4-digit PIN', style: context.text.titleMedium),
          const SizedBox(height: Insets.xs),
          AnimatedOpacity(
            opacity: _error ? 1 : 0,
            duration: Motion.fast,
            child: Text("PINs didn't match — try again", style: TextStyle(color: t.danger, fontSize: 13)),
          ),
          const SizedBox(height: Insets.lg),
          PinDots(filled: _entered.length, error: _error),
          const Spacer(flex: 1),
          PinKeypad(onDigit: _tap, onBackspace: _backspace),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
