import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'prefs.dart';

/// PIN hashing + biometric check for the app lock. The PIN itself is never
/// stored — only a salted SHA-256 hash, so a backup/restore or a rooted
/// device poking at SharedPreferences can't recover it.
class LockService {
  final LocalAuthentication _auth = LocalAuthentication();

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _randomSalt() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  void setPin(Prefs prefs, String pin) {
    final salt = _randomSalt();
    prefs.pinSalt = salt;
    prefs.pinHash = _hash(pin, salt);
  }

  bool verifyPin(Prefs prefs, String pin) {
    final salt = prefs.pinSalt;
    final hash = prefs.pinHash;
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  void clearPin(Prefs prefs) {
    prefs.pinHash = null;
    prefs.pinSalt = null;
    prefs.biometricEnabled = false;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Pocket Flow',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
