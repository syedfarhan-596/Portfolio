import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../state/wallet_state.dart';
import '../../services/lock_service.dart';

final lockServiceProvider = Provider<LockService>((ref) => LockService());

/// Full-screen PIN/biometric gate shown before the app's own content.
/// Deliberately has no access to wallet data — it's a pure auth check.
class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _entered = '';
  bool _error = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final prefs = ref.read(prefsProvider);
    if (!prefs.biometricEnabled || _checkingBiometric) return;
    _checkingBiometric = true;
    final ok = await ref.read(lockServiceProvider).authenticateWithBiometrics();
    _checkingBiometric = false;
    if (ok) widget.onUnlocked();
  }

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
    final prefs = ref.read(prefsProvider);
    final ok = ref.read(lockServiceProvider).verifyPin(prefs, _entered);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final prefs = ref.read(prefsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(Icons.lock_rounded, color: t.accentA, size: 44),
            const SizedBox(height: Insets.md),
            Text('Enter PIN', style: context.text.titleLarge),
            const SizedBox(height: Insets.xs),
            AnimatedOpacity(
              opacity: _error ? 1 : 0,
              duration: Motion.fast,
              child: Text('Incorrect PIN', style: TextStyle(color: t.danger, fontSize: 13)),
            ),
            const SizedBox(height: Insets.lg),
            PinDots(filled: _entered.length, error: _error),
            const Spacer(flex: 1),
            if (prefs.biometricEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.md),
                child: GestureDetector(
                  onTap: _tryBiometric,
                  child: Icon(Icons.fingerprint_rounded, color: t.accentA, size: 36),
                ),
              ),
            PinKeypad(onDigit: _tap, onBackspace: _backspace),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class PinDots extends StatelessWidget {
  final int filled;
  final bool error;
  const PinDots({super.key, required this.filled, required this.error});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? (error ? t.danger : t.accentA) : Colors.transparent,
            border: Border.all(color: error ? t.danger : t.accentA, width: 1.5),
          ),
        );
      }),
    );
  }
}

/// Shared numeric keypad used by both the unlock screen and PIN setup.
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const PinKeypad({super.key, required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) => _key(context, key)).toList(),
              ))
          .toList(),
    );
  }

  Widget _key(BuildContext context, String key) {
    final t = context.tokens;
    if (key.isEmpty) return const SizedBox(width: 76, height: 64);
    return SizedBox(
      width: 76,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
          child: Center(
            child: key == '⌫'
                ? Icon(Icons.backspace_outlined, color: t.textMid, size: 22)
                : Text(key, style: context.text.headlineSmall?.copyWith(color: t.textHigh)),
          ),
        ),
      ),
    );
  }
}
