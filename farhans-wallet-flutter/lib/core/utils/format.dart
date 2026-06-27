import 'package:intl/intl.dart';

class Money {
  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String format(double amount) => _inr.format(amount);

  static String short(double amount) {
    final a = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (a >= 10000000) return '$sign₹${(a / 10000000).toStringAsFixed(2)}Cr';
    if (a >= 100000) return '$sign₹${(a / 100000).toStringAsFixed(2)}L';
    if (a >= 1000) return '$sign₹${(a / 1000).toStringAsFixed(1)}K';
    return '$sign₹${a.toStringAsFixed(0)}';
  }
}

class Dates {
  static final _date = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _time = DateFormat('hh:mm a');
  static final _month = DateFormat('MMM yyyy');
  static final _day = DateFormat('EEE, dd MMM');

  static DateTime _d(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  static String date(int ms) => _date.format(_d(ms));
  static String dateTime(int ms) => _dateTime.format(_d(ms));
  static String time(int ms) => _time.format(_d(ms));
  static String month(int ms) => _month.format(_d(ms));
  static String day(int ms) => _day.format(_d(ms));

  static String monthKey(int ms) {
    final d = _d(ms);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }

  static String monthKeyNow() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }
}
