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
