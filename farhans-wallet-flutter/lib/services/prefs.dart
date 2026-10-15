import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over SharedPreferences for app settings.
class Prefs {
  final SharedPreferences _sp;
  Prefs(this._sp);

  static Future<Prefs> create() async => Prefs(await SharedPreferences.getInstance());

  bool get reminderEnabled => _sp.getBool('reminder_enabled') ?? true;
  set reminderEnabled(bool v) => _sp.setBool('reminder_enabled', v);

  int get reminderHour => _sp.getInt('reminder_hour') ?? 23;
  set reminderHour(int v) => _sp.setInt('reminder_hour', v);

  int get reminderMinute => _sp.getInt('reminder_minute') ?? 0;
  set reminderMinute(int v) => _sp.setInt('reminder_minute', v);

  bool get smsCapture => _sp.getBool('sms_capture') ?? true;
  set smsCapture(bool v) => _sp.setBool('sms_capture', v);

  /// Result of the last SMS permission request — lets Settings show a clear
  /// warning instead of capture silently doing nothing when permission was
  /// denied (or auto-revoked by Android for being unused).
  bool get smsPermGranted => _sp.getBool('sms_perm_granted') ?? false;
  set smsPermGranted(bool v) => _sp.setBool('sms_perm_granted', v);

  /// Epoch millis of the newest SMS already captured. Seeded to install time so
  /// pre-existing (old) messages are never imported.
  int get lastSmsScan => _sp.getInt('last_sms_scan') ?? 0;
  set lastSmsScan(int v) => _sp.setInt('last_sms_scan', v);

  /// 0 = system, 1 = light, 2 = dark
  int get themeMode => _sp.getInt('theme_mode') ?? 2;
  set themeMode(int v) => _sp.setInt('theme_mode', v);

  // ── App lock ──
  bool get appLockEnabled => _sp.getBool('app_lock_enabled') ?? false;
  set appLockEnabled(bool v) => _sp.setBool('app_lock_enabled', v);

  /// SHA-256 of (salt + PIN), never the PIN itself.
  String? get pinHash => _sp.getString('pin_hash');
  set pinHash(String? v) {
    if (v == null) {
      _sp.remove('pin_hash');
    } else {
      _sp.setString('pin_hash', v);
    }
  }

  String? get pinSalt => _sp.getString('pin_salt');
  set pinSalt(String? v) {
    if (v == null) {
      _sp.remove('pin_salt');
    } else {
      _sp.setString('pin_salt', v);
    }
  }

  bool get biometricEnabled => _sp.getBool('biometric_enabled') ?? false;
  set biometricEnabled(bool v) => _sp.setBool('biometric_enabled', v);

  // ── Onboarding ──
  String get userName => _sp.getString('user_name') ?? '';
  set userName(String v) => _sp.setString('user_name', v);

  /// Null means this key has never been set — used once at startup to tell
  /// a genuinely fresh install (show onboarding) apart from an existing
  /// install upgrading to the version that introduced onboarding (don't).
  bool? get onboardingCompleteRaw => _sp.getBool('onboarding_complete');
  bool get onboardingComplete => onboardingCompleteRaw ?? false;
  set onboardingComplete(bool v) => _sp.setBool('onboarding_complete', v);
}
