import '../data/models.dart';

class ParsedSms {
  final double amount;
  final TxnType type; // expense (debit) or income (credit)
  final String merchant;
  final String? ref;
  final String? bankHint;
  final bool isCreditCard;
  const ParsedSms(this.amount, this.type, this.merchant, this.ref, this.bankHint,
      {this.isCreditCard = false});
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

  // Bank/marketing SMS that mention money but are not real transaction alerts.
  static final _promoWords = [
    'cashback up to', 'up to ₹', 'upto ₹', '% off', '% cashback', 'flat off', 'flat ₹',
    'mega sale', 'sale is live', 'offer valid', 'limited period', 'limited time',
    'hurry', 'lucky draw', 'click here', 'apply now', 'pre-approved', 'preapproved',
    'pre approved', 'instant loan', 'insta loan', 'personal loan of', 'loan up to',
    'loan offer', 't&c apply', 'tnc apply', 'terms and conditions apply', 'unsubscribe',
    'download now', 'install now', 'book now', 'shop now', 'explore now',
    'grab the deal', 'deal of the day', 'exclusive offer', 'new arrival',
    'coupon code', 'promo code', 'voucher code', 'congratulations you',
    'you have won', "you've won", 'redeem now', 'free gift', 'starting at just',
    'get flat', 'save up to', 'lowest price', 'best offer', 'special offer',
    'welcome offer', 'festive offer', 'bumper offer', 'win rewards', 'win prizes',
    'reply stop', 'know more', 'call now', 'visit nearest branch to avail',
    'eligible for a loan', 'increase your limit', 'activate now', 'upgrade now',
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
    r'\b(hdfc|icici|state bank of india|sbi card|sbi|axis|kotak|yes bank|punjab national bank|pnb|bank of baroda|bob|canara|idfc|indusind|federal|rbl|au bank|au small finance|paytm|phonepe|gpay|amazon pay)\b',
    caseSensitive: false,
  );
  static final _creditCardWords = [
    'credit card', 'card ending', 'card no. xx', 'card no xx', 'card xx',
    'avl limit', 'avl lmt', 'available limit', 'available credit limit',
    'credit limit', 'card statement', 'minimum amount due', 'min amount due',
    'total amount due', 'card outstanding', 'cardmember', 'card member',
  ];
  static final _debitCardWords = ['debit card'];
  // Very common across virtually every bank's card-transaction template,
  // regardless of exact wording: the word "card" near a masked/partial
  // card number, e.g. "card ending 1234", "Card XX1234", "card no. 1234".
  static final _cardNumberNearWord = RegExp(r'\bcard\b.{0,20}?\d{3,4}\b', caseSensitive: false);

  /// Normalize a raw bank match to the short code used in account names, e.g.
  /// "State Bank of India" -> "sbi".
  static String _normalizeBank(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('state bank') || r.contains('sbi')) return 'sbi';
    if (r.contains('punjab national') || r == 'pnb') return 'pnb';
    if (r.contains('bank of baroda') || r == 'bob') return 'bob';
    return r;
  }

  static bool looksLikeTransaction(String body) {
    final b = body.toLowerCase();
    if (_promoWords.any(b.contains)) return false;
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
    final bankMatch = _bankRe.firstMatch(body)?.group(0);
    final bank = bankMatch != null ? _normalizeBank(bankMatch) : null;
    final isCreditCard = (_creditCardWords.any(b.contains) || _cardNumberNearWord.hasMatch(b)) &&
        !_debitCardWords.any(b.contains);

    return ParsedSms(
      amount,
      type,
      merchant.length > 40 ? merchant.substring(0, 40) : merchant,
      ref,
      bank,
      isCreditCard: isCreditCard,
    );
  }

  /// Pick the account a parsed SMS should post to: match the bank name in the
  /// SMS against account names, preferring a credit-card account when the SMS
  /// is about a card and a non-card account otherwise (so e.g. an SBI Card
  /// charge doesn't land in the SBI savings account just because both
  /// accounts have "SBI" in their name). Returns 0 (unassigned) if no match.
  static int matchAccountId(List<Account> accounts, ParsedSms parsed) {
    final hint = parsed.bankHint?.toLowerCase();
    if (hint == null || hint.isEmpty) return 0;
    final candidates = accounts.where((a) {
      final n = a.name.toLowerCase();
      return n.contains(hint) || hint.contains(n);
    }).toList();
    if (candidates.isEmpty) return 0;
    final preferred = parsed.isCreditCard
        ? candidates.where((a) => a.type == AccountType.creditCard).firstOrNull
        : candidates.where((a) => a.type != AccountType.creditCard).firstOrNull;
    return (preferred ?? candidates.first).id ?? 0;
  }
}
