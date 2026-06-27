import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/prefs.dart';
import 'state/wallet_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  final prefs = await Prefs.create();
  // Seed to install time so only SMS received after installing are captured.
  if (prefs.lastSmsScan == 0) {
    prefs.lastSmsScan = DateTime.now().millisecondsSinceEpoch;
  }

  final notifications = NotificationService();
  await notifications.init();
  if (prefs.reminderEnabled) {
    await notifications.scheduleDaily(prefs.reminderHour, prefs.reminderMinute);
  }

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const FarhansWalletApp(),
    ),
  );
}
