import 'package:another_telephony/telephony.dart';

class SmsRecord {
  final String body;
  final int date;
  const SmsRecord(this.body, this.date);
}

/// Reads bank/UPI SMS so transactions can be auto-detected — fully on device.
class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<bool> requestPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<List<SmsRecord>> readInbox({int limit = 300}) async {
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    return messages
        .take(limit)
        .map((m) => SmsRecord(m.body ?? '', m.date ?? DateTime.now().millisecondsSinceEpoch))
        .where((r) => r.body.isNotEmpty)
        .toList();
  }

  void listenIncoming(void Function(SmsRecord) onMessage) {
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          onMessage(SmsRecord(
            message.body ?? '',
            message.date ?? DateTime.now().millisecondsSinceEpoch,
          ));
        },
        listenInBackground: false,
      );
    } catch (_) {
      // No SMS permission yet — listening will be retried after it's granted.
    }
  }
}
