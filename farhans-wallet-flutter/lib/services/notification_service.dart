import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _reminderChannel = 'reminder';
  static const _txnChannel = 'txn_alerts';

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // The app targets India; using IST keeps the 11 PM reminder accurate.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancel(1001);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      1001,
      "Time to log today's expenses 💸",
      'Add what you spent today — food, friends, cash — so your balances stay accurate.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannel,
          'Daily Reminders',
          channelDescription: 'Reminds you every night to log your expenses',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Exact alarms survive Doze/App Standby so the reminder actually fires at
  /// the chosen time instead of being silently deferred by hours; fall back
  /// to inexact if the OS won't grant the exact-alarm permission.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      final granted = await android?.requestExactAlarmsPermission();
      if (granted == true) return AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> cancelReminder() async {
    await init();
    await _plugin.cancel(1001);
  }

  /// Schedules a monthly reminder [daysBefore] the given day-of-month, for
  /// one credit-card account. Repeats automatically every month — no need
  /// to reschedule after it fires, same as the daily reminder.
  Future<void> scheduleCardDue(
    int accountId,
    String accountName,
    int dueDay, {
    int daysBefore = 3,
  }) async {
    await init();
    final id = 3000 + accountId;
    await _plugin.cancel(id);

    int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;
    final now = tz.TZDateTime.now(tz.local);
    var year = now.year;
    var month = now.month;
    var reminderDay = (dueDay - daysBefore).clamp(1, daysInMonth(year, month));
    var scheduled = tz.TZDateTime(tz.local, year, month, reminderDay, 10, 0);
    if (!scheduled.isAfter(now)) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      reminderDay = (dueDay - daysBefore).clamp(1, daysInMonth(year, month));
      scheduled = tz.TZDateTime(tz.local, year, month, reminderDay, 10, 0);
    }

    await _plugin.zonedSchedule(
      id,
      '$accountName bill due soon',
      'Due on day $dueDay of this month — pay before then to avoid a late fee.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannel,
          'Daily Reminders',
          channelDescription: 'Reminds you before a credit card bill is due',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancelCardDue(int accountId) async {
    await init();
    await _plugin.cancel(3000 + accountId);
  }

  Future<void> showTxnDetected(String title, String body) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _txnChannel,
          'Transaction Alerts',
          channelDescription: 'Notifies when a new transaction is detected from SMS',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
