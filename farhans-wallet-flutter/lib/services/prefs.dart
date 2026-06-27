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

  int get defaultUpiAccountId => _sp.getInt('default_upi_account') ?? -1;
  set defaultUpiAccountId(int v) => _sp.setInt('default_upi_account', v);

  /// 0 = system, 1 = light, 2 = dark
  int get themeMode => _sp.getInt('theme_mode') ?? 2;
  set themeMode(int v) => _sp.setInt('theme_mode', v);
}
