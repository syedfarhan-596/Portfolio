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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await init();
    await _plugin.cancel(1001);
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
