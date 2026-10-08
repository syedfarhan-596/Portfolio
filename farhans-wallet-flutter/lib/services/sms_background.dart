import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'notification_service.dart';
import 'prefs.dart';
import 'sms_parser.dart';

/// Runs in a SEPARATE background isolate when an SMS arrives while the app is
/// not in the foreground (including when it's been killed). It opens the local
/// DB directly, adds the transaction, and shows a notification.
///
/// Must stay a top-level function annotated with @pragma('vm:entry-point') so
/// the engine can find it from the background isolate.
@pragma('vm:entry-point')
Future<void> smsBackgroundHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final body = message.body ?? '';
  if (body.isEmpty) return;
  final date = message.date ?? DateTime.now().millisecondsSinceEpoch;

  final prefs = await Prefs.create();
  if (!prefs.smsCapture) return;
  if (date > prefs.lastSmsScan) prefs.lastSmsScan = date;

  final parsed = SmsParser.parse(body);
  if (parsed == null) return;

  final repo = Repository(AppDatabase.instance);
  if (parsed.ref != null && await repo.upiRefExists(parsed.ref!)) return;

  final pattern = await repo.getOrCreatePattern(SmsPattern.signatureOf(body), seenAt: date);
  if (pattern.alwaysIgnore) return;

  final accounts = await repo.accounts();
  final heuristicAccountId = SmsParser.matchAccountId(accounts, parsed); // 0 = unassigned
  final learnedCategory = await repo.lastCategoryForMerchant(parsed.merchant, parsed.type);
  final trusted = pattern.autoConfirm;

  await repo.upsertTxn(Txn(
    type: trusted ? (pattern.lastType ?? parsed.type) : parsed.type,
    amount: parsed.amount,
    accountId: trusted ? (pattern.lastAccountId ?? heuristicAccountId) : heuristicAccountId,
    categoryId: trusted ? (pattern.lastCategoryId ?? learnedCategory) : learnedCategory,
    merchant: parsed.merchant,
    dateTime: date,
    source: TxnSource.sms,
    status: trusted ? TxnStatus.confirmed : TxnStatus.pending,
    upiRef: parsed.ref,
    rawSms: body,
  ));

  final notif = NotificationService();
  await notif.init();
  final credited = parsed.type == TxnType.income;
  final where = parsed.merchant.isNotEmpty ? ' · ${parsed.merchant}' : '';
  final amountText = '${credited ? '+' : '-'}₹${parsed.amount.toStringAsFixed(2)}$where';
  await notif.showTxnDetected(
    credited ? 'Money received' : 'Money spent',
    trusted ? amountText : '$amountText — tap to confirm & categorize',
  );
}
