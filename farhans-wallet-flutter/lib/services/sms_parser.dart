import '../data/models.dart';

class ParsedSms {
  final double amount;
  final TxnType type; // expense (debit) or income (credit)
  final String merchant;
  final String? ref;
  final String? bankHint;
  const ParsedSms(this.amount, this.type, this.merchant, this.ref, this.bankHint);
}

/// Heuristic parser for Indian bank / UPI alert SMS. Mirrors the original app.
class SmsParser {
  static final _debit = [
    'debited', 'debit', 'spent', 'paid', 'sent', 'withdrawn',
    'purchase', 'deducted', 'txn of', 'payment of'
  ];
  static final _credit = [
    'credited', 'credit', 'received', 'deposited', 'added', 'refund'
  ];

  static final _amount = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final _refRe = RegExp(
    r'(?:ref(?:erence)?(?:\s*no)?|upi(?:\s*ref)?|txn(?:\s*id)?|utr)[:\s#]*([a-z0-9]{6,})',
    caseSensitive: false,
  );
  static final _merchantRe = RegExp(
    r'(?:to|at|towards|vpa|to vpa)\s+([a-z0-9@._\- ]{3,40}?)(?:\s+(?:on|ref|upi|txn|a/c|bal|avl)|[.\n]|$)',
    caseSensitive: false,
  );
  static final _bankRe = RegExp(
    r'\b(hdfc|icici|sbi|axis|kotak|yes bank|pnb|bob|canara|idfc|indusind|federal|rbl|au bank|paytm|phonepe|gpay|amazon pay)\b',
    caseSensitive: false,
  );

  static bool looksLikeTransaction(String body) {
    final b = body.toLowerCase();
    final hasMoney = _amount.hasMatch(body);
    final hasAction = [..._debit, ..._credit].any(b.contains);
    return hasMoney && hasAction;
  }

  static ParsedSms? parse(String body) {
    if (!looksLikeTransaction(body)) return null;
    final b = body.toLowerCase();
    final m = _amount.firstMatch(body);
    if (m == null) return null;
    final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final isCredit = _credit.any(b.contains) && !_debit.any(b.contains);
    final type = isCredit
        ? TxnType.income
        : (_debit.any(b.contains) ? TxnType.expense : TxnType.income);

    final ref = _refRe.firstMatch(body)?.group(1);
    final merchant = (_merchantRe.firstMatch(body)?.group(1) ?? '')
        .trim()
        .replaceAll(RegExp(r'[.,]+$'), '');
    final bank = _bankRe.firstMatch(body)?.group(0)?.toUpperCase();

    return ParsedSms(amount, type, merchant.length > 40 ? merchant.substring(0, 40) : merchant, ref, bank);
  }
}
