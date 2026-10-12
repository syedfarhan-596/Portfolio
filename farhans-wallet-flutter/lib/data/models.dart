// Domain models — mirror the original app's schema 1:1 so behaviour is preserved.

enum AccountType { bank, cash, creditCard, wallet }

enum TxnType { expense, income, transfer }

enum TxnSource { manual, sms, upi, import_ }

enum TxnStatus { confirmed, pending }

enum DebtDirection { iLent, iBorrowed }

enum InvestmentType { stock, mutualFund, gold, crypto, fd, bond, other }

T _enumFromName<T>(List<T> values, String name, T fallback) {
  for (final v in values) {
    if ((v as Enum).name == name) return v;
  }
  return fallback;
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final double openingBalance;
  final String colorHex;
  final String icon;
  final double? creditLimit;
  final bool includeInTotal;
  final bool archived;
  final int sortOrder;

  /// Day of month (1-31) the credit-card bill is due, if the user has set
  /// one. Drives the due-date reminder notification; null means no reminder.
  final int? dueDay;

  const Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.colorHex = '#6C5CE7',
    this.icon = 'account_balance',
    this.creditLimit,
    this.includeInTotal = true,
    this.archived = false,
    this.sortOrder = 0,
    this.dueDay,
  });

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? openingBalance,
    String? colorHex,
    String? icon,
    double? creditLimit,
    bool? includeInTotal,
    bool? archived,
    int? sortOrder,
    int? dueDay,
  }) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        openingBalance: openingBalance ?? this.openingBalance,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
        creditLimit: creditLimit ?? this.creditLimit,
        includeInTotal: includeInTotal ?? this.includeInTotal,
        archived: archived ?? this.archived,
        sortOrder: sortOrder ?? this.sortOrder,
        dueDay: dueDay ?? this.dueDay,
      );

  /// copyWith can't set a nullable field back to null, so use this to clear
  /// [dueDay] explicitly (e.g. when the account stops being a credit card).
  Account withDueDay(int? dueDay) => Account(
        id: id,
        name: name,
        type: type,
        openingBalance: openingBalance,
        colorHex: colorHex,
        icon: icon,
        creditLimit: creditLimit,
        includeInTotal: includeInTotal,
        archived: archived,
        sortOrder: sortOrder,
        dueDay: dueDay,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'colorHex': colorHex,
        'icon': icon,
        'creditLimit': creditLimit,
        'includeInTotal': includeInTotal ? 1 : 0,
        'archived': archived ? 1 : 0,
        'sortOrder': sortOrder,
        'dueDay': dueDay,
      };

  factory Account.fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: _enumFromName(AccountType.values, m['type'] as String, AccountType.bank),
        openingBalance: (m['openingBalance'] as num?)?.toDouble() ?? 0,
        colorHex: m['colorHex'] as String? ?? '#6C5CE7',
        icon: m['icon'] as String? ?? 'account_balance',
        creditLimit: (m['creditLimit'] as num?)?.toDouble(),
        includeInTotal: (m['includeInTotal'] as int? ?? 1) == 1,
        archived: (m['archived'] as int? ?? 0) == 1,
        sortOrder: m['sortOrder'] as int? ?? 0,
        dueDay: m['dueDay'] as int?,
      );
}

class Category {
  final int? id;
  final String name;
  final TxnType type;
  final String icon;
  final String colorHex;
  final int sortOrder;
  final bool isDefault;

  const Category({
    this.id,
    required this.name,
    this.type = TxnType.expense,
    this.icon = 'category',
    this.colorHex = '#00B894',
    this.sortOrder = 0,
    this.isDefault = false,
  });

  Category copyWith({
    int? id,
    String? name,
    TxnType? type,
    String? icon,
    String? colorHex,
    int? sortOrder,
    bool? isDefault,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        icon: icon ?? this.icon,
        colorHex: colorHex ?? this.colorHex,
        sortOrder: sortOrder ?? this.sortOrder,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'colorHex': colorHex,
        'sortOrder': sortOrder,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: _enumFromName(TxnType.values, m['type'] as String, TxnType.expense),
        icon: m['icon'] as String? ?? 'category',
        colorHex: m['colorHex'] as String? ?? '#00B894',
        sortOrder: m['sortOrder'] as int? ?? 0,
        isDefault: (m['isDefault'] as int? ?? 0) == 1,
      );
}

class Txn {
  final int? id;
  final TxnType type;
  final double amount;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final String note;
  final String merchant;
  final int dateTime; // epoch millis
  final TxnSource source;
  final TxnStatus status;
  final String? contactName;
  final String? contactKey;
  final String? upiRef;
  final String? rawSms;
  final int? debtId;

  const Txn({
    this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note = '',
    this.merchant = '',
    required this.dateTime,
    this.source = TxnSource.manual,
    this.status = TxnStatus.confirmed,
    this.contactName,
    this.contactKey,
    this.upiRef,
    this.rawSms,
    this.debtId,
  });

  Txn copyWith({
    int? id,
    TxnType? type,
    double? amount,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    String? note,
    String? merchant,
    int? dateTime,
    TxnSource? source,
    TxnStatus? status,
    String? contactName,
    String? contactKey,
    String? upiRef,
    String? rawSms,
    int? debtId,
  }) =>
      Txn(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId ?? this.toAccountId,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        merchant: merchant ?? this.merchant,
        dateTime: dateTime ?? this.dateTime,
        source: source ?? this.source,
        status: status ?? this.status,
        contactName: contactName ?? this.contactName,
        contactKey: contactKey ?? this.contactKey,
        upiRef: upiRef ?? this.upiRef,
        rawSms: rawSms ?? this.rawSms,
        debtId: debtId ?? this.debtId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'note': note,
        'merchant': merchant,
        'dateTime': dateTime,
        'source': source.name,
        'status': status.name,
        'contactName': contactName,
        'contactKey': contactKey,
        'upiRef': upiRef,
        'rawSms': rawSms,
        'debtId': debtId,
      };

  factory Txn.fromMap(Map<String, Object?> m) => Txn(
        id: m['id'] as int?,
        type: _enumFromName(TxnType.values, m['type'] as String, TxnType.expense),
        amount: (m['amount'] as num).toDouble(),
        accountId: m['accountId'] as int,
        toAccountId: m['toAccountId'] as int?,
        categoryId: m['categoryId'] as int?,
        note: m['note'] as String? ?? '',
        merchant: m['merchant'] as String? ?? '',
        dateTime: m['dateTime'] as int,
        source: _enumFromName(TxnSource.values, m['source'] as String? ?? 'manual', TxnSource.manual),
        status: _enumFromName(TxnStatus.values, m['status'] as String? ?? 'confirmed', TxnStatus.confirmed),
        contactName: m['contactName'] as String?,
        contactKey: m['contactKey'] as String?,
        upiRef: m['upiRef'] as String?,
        rawSms: m['rawSms'] as String?,
        debtId: m['debtId'] as int?,
      );
}

class Debt {
  final int? id;
  final String contactName;
  final String? contactKey;
  final DebtDirection direction;
  final double amount;
  final double paidAmount;
  final String note;
  final int createdAt;
  final bool dueAfterSalary;
  final bool settled;
  final int? settledAt;
  final int? accountId;

  /// Id of the transaction that reflects this due's principal into [accountId],
  /// or null if the due was recorded without touching any account balance.
  final int? principalTxnId;

  const Debt({
    this.id,
    required this.contactName,
    this.contactKey,
    required this.direction,
    required this.amount,
    this.paidAmount = 0,
    this.note = '',
    required this.createdAt,
    this.dueAfterSalary = false,
    this.settled = false,
    this.settledAt,
    this.accountId,
    this.principalTxnId,
  });

  double get remaining => (amount - paidAmount).clamp(0, double.infinity);

  Debt copyWith({
    int? id,
    String? contactName,
    String? contactKey,
    DebtDirection? direction,
    double? amount,
    double? paidAmount,
    String? note,
    int? createdAt,
    bool? dueAfterSalary,
    bool? settled,
    int? settledAt,
    int? accountId,
    int? principalTxnId,
  }) =>
      Debt(
        id: id ?? this.id,
        contactName: contactName ?? this.contactName,
        contactKey: contactKey ?? this.contactKey,
        direction: direction ?? this.direction,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        dueAfterSalary: dueAfterSalary ?? this.dueAfterSalary,
        settled: settled ?? this.settled,
        settledAt: settledAt ?? this.settledAt,
        accountId: accountId ?? this.accountId,
        principalTxnId: principalTxnId ?? this.principalTxnId,
      );

  /// copyWith can't set nullable fields back to null, so use this to rebuild a
  /// due with explicit account / principal-transaction links.
  Debt withLinks({required int id, required int? accountId, required int? principalTxnId}) =>
      Debt(
        id: id,
        contactName: contactName,
        contactKey: contactKey,
        direction: direction,
        amount: amount,
        paidAmount: paidAmount,
        note: note,
        createdAt: createdAt,
        dueAfterSalary: dueAfterSalary,
        settled: settled,
        settledAt: settledAt,
        accountId: accountId,
        principalTxnId: principalTxnId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'contactName': contactName,
        'contactKey': contactKey,
        'direction': direction.name,
        'amount': amount,
        'paidAmount': paidAmount,
        'note': note,
        'createdAt': createdAt,
        'dueAfterSalary': dueAfterSalary ? 1 : 0,
        'settled': settled ? 1 : 0,
        'settledAt': settledAt,
        'accountId': accountId,
        'principalTxnId': principalTxnId,
      };

  factory Debt.fromMap(Map<String, Object?> m) => Debt(
        id: m['id'] as int?,
        contactName: m['contactName'] as String,
        contactKey: m['contactKey'] as String?,
        direction: _enumFromName(DebtDirection.values, m['direction'] as String, DebtDirection.iLent),
        amount: (m['amount'] as num).toDouble(),
        paidAmount: (m['paidAmount'] as num?)?.toDouble() ?? 0,
        note: m['note'] as String? ?? '',
        createdAt: m['createdAt'] as int,
        dueAfterSalary: (m['dueAfterSalary'] as int? ?? 0) == 1,
        settled: (m['settled'] as int? ?? 0) == 1,
        settledAt: m['settledAt'] as int?,
        accountId: m['accountId'] as int?,
        principalTxnId: m['principalTxnId'] as int?,
      );
}

class Investment {
  final int? id;
  final String name;
  final InvestmentType type;
  final double quantity;
  final double investedAmount;
  final double? currentValue;
  final int? accountId;
  final int createdAt;
  final String note;
  final bool sold;

  const Investment({
    this.id,
    required this.name,
    this.type = InvestmentType.stock,
    this.quantity = 0,
    required this.investedAmount,
    this.currentValue,
    this.accountId,
    required this.createdAt,
    this.note = '',
    this.sold = false,
  });

  double get current => currentValue ?? investedAmount;

  Investment copyWith({
    int? id,
    String? name,
    InvestmentType? type,
    double? quantity,
    double? investedAmount,
    double? currentValue,
    int? accountId,
    int? createdAt,
    String? note,
    bool? sold,
  }) =>
      Investment(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        quantity: quantity ?? this.quantity,
        investedAmount: investedAmount ?? this.investedAmount,
        currentValue: currentValue ?? this.currentValue,
        accountId: accountId ?? this.accountId,
        createdAt: createdAt ?? this.createdAt,
        note: note ?? this.note,
        sold: sold ?? this.sold,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'quantity': quantity,
        'investedAmount': investedAmount,
        'currentValue': currentValue,
        'accountId': accountId,
        'createdAt': createdAt,
        'note': note,
        'sold': sold ? 1 : 0,
      };

  factory Investment.fromMap(Map<String, Object?> m) => Investment(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: _enumFromName(InvestmentType.values, m['type'] as String, InvestmentType.stock),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        investedAmount: (m['investedAmount'] as num).toDouble(),
        currentValue: (m['currentValue'] as num?)?.toDouble(),
        accountId: m['accountId'] as int?,
        createdAt: m['createdAt'] as int,
        note: m['note'] as String? ?? '',
        sold: (m['sold'] as int? ?? 0) == 1,
      );
}

/// Aggregate view models used by the UI layer.
class AccountBalance {
  final Account account;
  final double balance;
  const AccountBalance(this.account, this.balance);
}

class PeopleSummary {
  final String contactName;
  final String? contactKey;
  final double net; // + they owe you, - you owe them
  final double toReceive;
  final double toPay;
  final bool dueAfterSalary;
  final List<Debt> debts;
  const PeopleSummary({
    required this.contactName,
    required this.contactKey,
    required this.net,
    required this.toReceive,
    required this.toPay,
    required this.dueAfterSalary,
    required this.debts,
  });
}

enum RecurringCadence { weekly, monthly, yearly }

extension RecurringCadenceX on RecurringCadence {
  /// Approximate period length, used to project the next expected charge
  /// and to normalize amounts onto a common monthly footing.
  int get days => switch (this) {
        RecurringCadence.weekly => 7,
        RecurringCadence.monthly => 30,
        RecurringCadence.yearly => 365,
      };

  String get label => switch (this) {
        RecurringCadence.weekly => 'Weekly',
        RecurringCadence.monthly => 'Monthly',
        RecurringCadence.yearly => 'Yearly',
      };

  double get perMonthFactor => switch (this) {
        RecurringCadence.weekly => 365 / 12 / 7,
        RecurringCadence.monthly => 1,
        RecurringCadence.yearly => 1 / 12,
      };
}

/// A merchant/account/type combination whose transactions repeat at a
/// roughly constant interval and amount — detected purely by looking back
/// over existing confirmed transactions (see RecurringDetector). Not
/// persisted: it's recomputed from the transaction list on every load, the
/// same way AccountBalance is.
class RecurringSeries {
  final String merchant;
  final int accountId;
  final int? categoryId;
  final TxnType type;
  final RecurringCadence cadence;
  final int occurrenceCount;
  final double averageAmount;
  final double lastAmount;
  final int lastDate;
  final int nextExpectedDate;

  const RecurringSeries({
    required this.merchant,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.cadence,
    required this.occurrenceCount,
    required this.averageAmount,
    required this.lastAmount,
    required this.lastDate,
    required this.nextExpectedDate,
  });

  /// Three or more consistently-spaced occurrences is a real pattern;
  /// exactly two is only a hint, shown but flagged as less certain.
  bool get confident => occurrenceCount >= 3;

  bool get isOverdue =>
      nextExpectedDate < DateTime.now().millisecondsSinceEpoch - cadence.days * 86400000;
}

/// A savings target the user is manually putting money toward — tracked as
/// its own running total, independent of any account balance, so setting a
/// goal never has to interfere with how real account balances are computed.
class SavingsGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final int? targetDate;
  final String colorHex;
  final String icon;
  final int createdAt;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.targetDate,
    this.colorHex = '#6C5CE7',
    this.icon = 'savings',
    required this.createdAt,
  });

  bool get achieved => savedAmount >= targetAmount;
  double get pct => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble() : 0.0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);

  SavingsGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    int? targetDate,
    String? colorHex,
    String? icon,
    int? createdAt,
  }) =>
      SavingsGoal(
        id: id ?? this.id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        targetDate: targetDate ?? this.targetDate,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
        createdAt: createdAt ?? this.createdAt,
      );

  /// copyWith can't set a nullable field back to null, so use this to clear
  /// [targetDate] explicitly.
  SavingsGoal withTargetDate(int? targetDate) => SavingsGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        targetDate: targetDate,
        colorHex: colorHex,
        icon: icon,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': targetDate,
        'colorHex': colorHex,
        'icon': icon,
        'createdAt': createdAt,
      };

  factory SavingsGoal.fromMap(Map<String, Object?> m) => SavingsGoal(
        id: m['id'] as int?,
        name: m['name'] as String,
        targetAmount: (m['targetAmount'] as num).toDouble(),
        savedAmount: (m['savedAmount'] as num?)?.toDouble() ?? 0,
        targetDate: m['targetDate'] as int?,
        colorHex: m['colorHex'] as String? ?? '#6C5CE7',
        icon: m['icon'] as String? ?? 'savings',
        createdAt: m['createdAt'] as int,
      );
}

enum InsightTone { positive, negative, neutral }

/// One plain-English observation about spending patterns, generated fresh
/// from transaction history on every load (see InsightGenerator) — never
/// stored, since it's always a live read of the current data.
class SpendingInsight {
  final InsightTone tone;
  final String text;
  const SpendingInsight({required this.tone, required this.text});
}

/// Net worth as it was (or, for past points, approximately was) at one point
/// in time — see NetWorthHistory for how past points are reconstructed.
class NetWorthPoint {
  final int dateTime;
  final double netWorth;
  const NetWorthPoint(this.dateTime, this.netWorth);
}

/// A user-set monthly spending cap for one expense category.
class Budget {
  final int? id;
  final int categoryId;
  final double monthlyLimit;

  const Budget({this.id, required this.categoryId, required this.monthlyLimit});

  Budget copyWith({int? id, int? categoryId, double? monthlyLimit}) => Budget(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'monthlyLimit': monthlyLimit,
      };

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as int?,
        categoryId: m['categoryId'] as int,
        monthlyLimit: (m['monthlyLimit'] as num).toDouble(),
      );
}

/// A budget paired with how much has actually been spent in that category
/// this month. Computed fresh on every load from [Budget] + the month's
/// confirmed transactions — not persisted itself.
class BudgetStatus {
  final Budget budget;
  final Category category;
  final double spent;
  const BudgetStatus({required this.budget, required this.category, required this.spent});

  double get remaining => budget.monthlyLimit - spent;
  double get pct => budget.monthlyLimit > 0 ? spent / budget.monthlyLimit : 0.0;
  bool get isOver => spent > budget.monthlyLimit;
  bool get isNearLimit => !isOver && pct >= 0.8;
}

/// Learned memory for one SMS "template" (a normalized signature shared by
/// every message with the same wording but different amounts/dates/refs).
/// Lets SMS capture get more confident over time instead of re-guessing the
/// same way, right or wrong, forever.
class SmsPattern {
  final int? id;
  final String signature;
  final int timesSeen;

  /// How many times in a row the account/category/type the user ended up
  /// saving matched [lastAccountId]/[lastCategoryId]/[lastType]. Resets to 1
  /// whenever they save something different. Crossing [autoConfirmStreak]
  /// flips [autoConfirm] on.
  final int consistentStreak;

  /// How many times this pattern was dismissed/deleted as not a real
  /// transaction. Crossing [autoRejectCount] flips [alwaysIgnore] on.
  final int timesRejected;

  final int? lastAccountId;
  final int? lastCategoryId;
  final TxnType? lastType;
  final bool autoConfirm;
  final bool alwaysIgnore;
  final int firstSeenAt;
  final int lastSeenAt;

  static const int autoConfirmStreak = 3;
  static const int autoRejectCount = 2;

  const SmsPattern({
    this.id,
    required this.signature,
    required this.timesSeen,
    required this.consistentStreak,
    required this.timesRejected,
    this.lastAccountId,
    this.lastCategoryId,
    this.lastType,
    required this.autoConfirm,
    required this.alwaysIgnore,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  /// Collapses a message to its template shape by blanking out every run of
  /// digits — amounts, dates, reference numbers, masked card digits, OTPs —
  /// so "Rs.500 spent at X on 12-10-26" and "Rs.620 spent at X on 20-10-26"
  /// are recognized as the same pattern.
  static String signatureOf(String body) {
    final blanked = body.toLowerCase().replaceAll(RegExp(r'[0-9]+'), '#');
    return blanked.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'signature': signature,
        'timesSeen': timesSeen,
        'consistentStreak': consistentStreak,
        'timesRejected': timesRejected,
        'lastAccountId': lastAccountId,
        'lastCategoryId': lastCategoryId,
        'lastType': lastType?.name,
        'autoConfirm': autoConfirm ? 1 : 0,
        'alwaysIgnore': alwaysIgnore ? 1 : 0,
        'firstSeenAt': firstSeenAt,
        'lastSeenAt': lastSeenAt,
      };

  factory SmsPattern.fromMap(Map<String, Object?> m) => SmsPattern(
        id: m['id'] as int?,
        signature: m['signature'] as String,
        timesSeen: m['timesSeen'] as int? ?? 0,
        consistentStreak: m['consistentStreak'] as int? ?? 0,
        timesRejected: m['timesRejected'] as int? ?? 0,
        lastAccountId: m['lastAccountId'] as int?,
        lastCategoryId: m['lastCategoryId'] as int?,
        lastType: (m['lastType'] as String?) == null
            ? null
            : _enumFromName(TxnType.values, m['lastType'] as String, TxnType.expense),
        autoConfirm: (m['autoConfirm'] as int? ?? 0) == 1,
        alwaysIgnore: (m['alwaysIgnore'] as int? ?? 0) == 1,
        firstSeenAt: m['firstSeenAt'] as int,
        lastSeenAt: m['lastSeenAt'] as int,
      );
}
