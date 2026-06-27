import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/format.dart';
import '../data/app_database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../services/contacts_service.dart';
import '../services/notification_service.dart';
import '../services/prefs.dart';
import '../services/sms_parser.dart';
import '../services/sms_service.dart';

/// Overridden in main() once SharedPreferences is loaded.
final prefsProvider = Provider<Prefs>((ref) => throw UnimplementedError());

final repositoryProvider = Provider<Repository>((ref) => Repository(AppDatabase.instance));
final notificationProvider = Provider<NotificationService>((ref) => NotificationService());
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());
final contactsServiceProvider = Provider<ContactsService>((ref) => ContactsService());

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  switch (ref.read(prefsProvider).themeMode) {
    case 1:
      return ThemeMode.light;
    case 0:
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
});

/// Immutable snapshot of all data + derived figures consumed by the UI.
class WalletData {
  final List<Account> accounts; // active only
  final List<Category> categories;
  final List<Txn> txns; // all
  final List<Debt> debts;
  final List<Investment> investments;

  WalletData({
    required this.accounts,
    required this.categories,
    required this.txns,
    required this.debts,
    required this.investments,
  });

  late final List<Txn> confirmed =
      txns.where((t) => t.status == TxnStatus.confirmed).toList();
  late final List<Txn> pending =
      txns.where((t) => t.status == TxnStatus.pending).toList();

  late final Map<int, Account> accountById = {
    for (final a in accounts)
      if (a.id != null) a.id!: a
  };
  late final Map<int, Category> categoryById = {
    for (final c in categories)
      if (c.id != null) c.id!: c
  };

  late final List<AccountBalance> balances = accounts
      .map((a) => AccountBalance(a, Repository.computeBalance(a, confirmed)))
      .toList();

  double balanceOf(int accountId) =>
      balances.firstWhere((b) => b.account.id == accountId,
          orElse: () => AccountBalance(accountById[accountId]!, 0)).balance;

  List<Category> categoriesOfType(TxnType type) =>
      categories.where((c) => c.type == type).toList();

  // ── Dashboard figures ──
  double get liquidTotal => balances
      .where((b) => b.account.type != AccountType.creditCard && b.account.includeInTotal)
      .fold(0.0, (s, b) => s + b.balance);

  double get creditOutstanding => balances
      .where((b) => b.account.type == AccountType.creditCard)
      .fold(0.0, (s, b) => s + b.balance);

  double get toReceive => debts
      .where((d) => !d.settled && d.direction == DebtDirection.iLent)
      .fold(0.0, (s, d) => s + d.remaining);

  double get toPay => debts
      .where((d) => !d.settled && d.direction == DebtDirection.iBorrowed)
      .fold(0.0, (s, d) => s + d.remaining);

  double get investedValue =>
      investments.where((i) => !i.sold).fold(0.0, (s, i) => s + i.current);

  double get investedCost =>
      investments.where((i) => !i.sold).fold(0.0, (s, i) => s + i.investedAmount);

  double get netWorth =>
      liquidTotal - creditOutstanding + (toReceive - toPay) + investedValue;

  double get monthExpense {
    final m = Dates.monthKeyNow();
    return confirmed
        .where((t) => t.type == TxnType.expense && Dates.monthKey(t.dateTime) == m)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get monthIncome {
    final m = Dates.monthKeyNow();
    return confirmed
        .where((t) => t.type == TxnType.income && Dates.monthKey(t.dateTime) == m)
        .fold(0.0, (s, t) => s + t.amount);
  }

  List<PeopleSummary> get people {
    final byName = <String, List<Debt>>{};
    for (final d in debts) {
      byName.putIfAbsent(d.contactName, () => []).add(d);
    }
    final list = byName.entries.map((e) {
      final ds = e.value..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final rec = ds
          .where((d) => !d.settled && d.direction == DebtDirection.iLent)
          .fold(0.0, (s, d) => s + d.remaining);
      final pay = ds
          .where((d) => !d.settled && d.direction == DebtDirection.iBorrowed)
          .fold(0.0, (s, d) => s + d.remaining);
      return PeopleSummary(
        contactName: e.key,
        contactKey: ds.isNotEmpty ? ds.first.contactKey : null,
        net: rec - pay,
        toReceive: rec,
        toPay: pay,
        dueAfterSalary: ds.any((d) => !d.settled && d.dueAfterSalary),
        debts: ds,
      );
    }).toList();
    list.sort((a, b) => b.net.abs().compareTo(a.net.abs()));
    return list;
  }

  double get portfolioGain => investedValue - investedCost;
  double get portfolioGainPct => investedCost > 0 ? portfolioGain / investedCost * 100 : 0;
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);

class WalletNotifier extends AsyncNotifier<WalletData> {
  Repository get _repo => ref.read(repositoryProvider);
  Prefs get _prefs => ref.read(prefsProvider);

  @override
  Future<WalletData> build() async {
    // Make sure newer default categories exist even on an upgraded DB.
    final db = await AppDatabase.instance.database;
    await AppDatabase.instance.ensureDefaultCategories(db);
    return _load();
  }

  Future<WalletData> _load() async {
    final results = await Future.wait([
      _repo.accounts(),
      _repo.categories(),
      _repo.transactions(),
      _repo.debts(),
      _repo.investments(),
    ]);
    return WalletData(
      accounts: results[0] as List<Account>,
      categories: results[1] as List<Category>,
      txns: results[2] as List<Txn>,
      debts: results[3] as List<Debt>,
      investments: results[4] as List<Investment>,
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _load());
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ── Accounts ──
  Future<void> saveAccount(Account a) async {
    await _repo.upsertAccount(a);
    await _refresh();
  }

  Future<void> deleteAccount(Account a) async {
    if (a.id != null) await _repo.deleteAccount(a.id!);
    await _refresh();
  }

  // ── Categories ──
  Future<void> saveCategory(Category c) async {
    await _repo.upsertCategory(c);
    await _refresh();
  }

  Future<void> deleteCategory(Category c) async {
    if (c.id != null) await _repo.deleteCategory(c.id!);
    await _refresh();
  }

  // ── Transactions ──
  Future<void> saveTxn(Txn t) async {
    await _repo.upsertTxn(t);
    await _refresh();
  }

  Future<void> deleteTxn(Txn t) async {
    if (t.id != null) await _repo.deleteTxn(t.id!);
    await _refresh();
  }

  Future<void> dismissPending(Txn t) async {
    if (t.id != null) await _repo.deleteTxn(t.id!);
    await _refresh();
  }

  // ── Debts / lending ──
  Future<void> saveDebt(Debt d) async {
    await _repo.upsertDebt(d);
    await _refresh();
  }

  Future<void> deleteDebt(Debt d) async {
    if (d.id != null) await _repo.deleteDebt(d.id!);
    await _refresh();
  }

  /// New lending/borrowing entry that reflects the principal into an account.
  Future<void> addLending(Debt d, int? accountId) async {
    final id = await _repo.upsertDebt(d.copyWith(accountId: accountId));
    if (accountId != null && accountId > 0) {
      final isLent = d.direction == DebtDirection.iLent;
      final type = isLent ? TxnType.expense : TxnType.income;
      final catName = isLent ? Cats.lent : Cats.borrowed;
      await _repo.upsertTxn(Txn(
        type: type,
        amount: d.amount,
        accountId: accountId,
        categoryId: await _repo.categoryIdByName(catName, type),
        note: (isLent ? 'Lent to ' : 'Borrowed from ') + d.contactName,
        dateTime: d.createdAt,
        contactName: d.contactName,
        contactKey: d.contactKey,
        debtId: id,
      ));
    }
    await _refresh();
  }

  Future<void> recordPayment(Debt d, double amount, int? accountId) async {
    final remaining = (d.amount - d.paidAmount).clamp(0.0, double.infinity);
    final pay = amount.clamp(0.0, remaining);
    if (pay <= 0) return;
    final newPaid = (d.paidAmount + pay).clamp(0.0, d.amount);
    final settled = newPaid >= d.amount - 0.01;
    await _repo.upsertDebt(d.copyWith(
      paidAmount: newPaid,
      settled: settled,
      settledAt: settled ? _now : d.settledAt,
    ));
    if (accountId != null && accountId > 0) {
      final isLent = d.direction == DebtDirection.iLent;
      final type = isLent ? TxnType.income : TxnType.expense;
      final catName = isLent ? Cats.repayment : Cats.settlement;
      await _repo.upsertTxn(Txn(
        type: type,
        amount: pay,
        accountId: accountId,
        categoryId: await _repo.categoryIdByName(catName, type),
        note: (isLent ? 'Repayment from ' : 'Paid to ') + d.contactName,
        dateTime: _now,
        contactName: d.contactName,
        contactKey: d.contactKey,
        debtId: d.id,
      ));
    }
    await _refresh();
  }

  // ── Credit card ──
  Future<void> payCreditCard(
      int cardId, int? fromAccountId, double amountFromBank, double amountFromPoints) async {
    if (amountFromBank > 0 && fromAccountId != null && fromAccountId > 0) {
      await _repo.upsertTxn(Txn(
        type: TxnType.transfer,
        amount: amountFromBank,
        accountId: fromAccountId,
        toAccountId: cardId,
        note: 'Credit card bill payment',
        dateTime: _now,
      ));
    }
    if (amountFromPoints > 0) {
      await _repo.upsertTxn(Txn(
        type: TxnType.income,
        amount: amountFromPoints,
        accountId: cardId,
        categoryId: await _repo.categoryIdByName(Cats.cardPoints, TxnType.income),
        note: 'Bill paid via reward points',
        dateTime: _now,
      ));
    }
    await _refresh();
  }

  // ── Investments ──
  Future<void> buyInvestment(Investment inv) async {
    await _repo.upsertInvestment(inv);
    if (inv.accountId != null && inv.accountId! > 0) {
      await _repo.upsertTxn(Txn(
        type: TxnType.expense,
        amount: inv.investedAmount,
        accountId: inv.accountId!,
        categoryId: await _repo.categoryIdByName(Cats.investment, TxnType.expense),
        note: 'Invested in ${inv.name}',
        merchant: inv.name,
        dateTime: inv.createdAt,
      ));
    }
    await _refresh();
  }

  Future<void> updateInvestment(Investment inv) async {
    await _repo.upsertInvestment(inv);
    await _refresh();
  }

  Future<void> deleteInvestment(Investment inv) async {
    if (inv.id != null) await _repo.deleteInvestment(inv.id!);
    await _refresh();
  }

  Future<void> sellInvestment(Investment inv, double saleAmount, int? accountId) async {
    await _repo.upsertInvestment(inv.copyWith(sold: true, currentValue: saleAmount));
    if (accountId != null && accountId > 0) {
      await _repo.upsertTxn(Txn(
        type: TxnType.income,
        amount: saleAmount,
        accountId: accountId,
        categoryId: await _repo.categoryIdByName(Cats.investReturn, TxnType.income),
        note: 'Sold ${inv.name}',
        merchant: inv.name,
        dateTime: _now,
      ));
    }
    await _refresh();
  }

  // ── SMS import ──
  Future<int> importSmsInbox() async {
    final sms = ref.read(smsServiceProvider);
    final granted = await sms.requestPermission();
    if (!granted) return -1;
    final records = await sms.readInbox();
    final accId = _prefs.defaultUpiAccountId > 0
        ? _prefs.defaultUpiAccountId
        : (state.value?.accounts.isNotEmpty == true ? state.value!.accounts.first.id! : 0);
    var count = 0;
    for (final r in records) {
      final parsed = SmsParser.parse(r.body);
      if (parsed == null) continue;
      if (parsed.ref != null && await _repo.upiRefExists(parsed.ref!)) continue;
      await _repo.upsertTxn(Txn(
        type: parsed.type,
        amount: parsed.amount,
        accountId: accId,
        merchant: parsed.merchant,
        dateTime: r.date,
        source: TxnSource.import_,
        status: TxnStatus.pending,
        upiRef: parsed.ref,
        rawSms: r.body,
      ));
      count++;
    }
    await _refresh();
    return count;
  }
}
