import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/format.dart';
import '../data/app_database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../services/backup_service.dart';
import '../services/contacts_service.dart';
import '../services/insight_generator.dart';
import '../services/networth_history.dart';
import '../services/notification_service.dart';
import '../services/prefs.dart';
import '../services/recurring_detector.dart';
import '../services/sms_background.dart';
import '../services/sms_parser.dart';
import '../services/sms_service.dart';

/// Overridden in main() once SharedPreferences is loaded.
final prefsProvider = Provider<Prefs>((ref) => throw UnimplementedError());

final repositoryProvider = Provider<Repository>((ref) => Repository(AppDatabase.instance));
final notificationProvider = Provider<NotificationService>((ref) => NotificationService());
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());
final contactsServiceProvider = Provider<ContactsService>((ref) => ContactsService());
final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

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
  final List<Budget> budgets;
  final List<SavingsGoal> goals;

  WalletData({
    required this.accounts,
    required this.categories,
    required this.txns,
    required this.debts,
    required this.investments,
    required this.budgets,
    required this.goals,
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

  late final List<RecurringSeries> recurringSeries = RecurringDetector.detect(confirmed);

  /// Recurring expense spend normalized to a monthly figure — a weekly
  /// subscription and a yearly one both roll up onto the same footing.
  double get monthlyRecurringTotal => recurringSeries
      .where((r) => r.type == TxnType.expense)
      .fold(0.0, (s, r) => s + r.averageAmount * r.cadence.perMonthFactor);

  /// Each set budget paired with how much has actually been spent in that
  /// category this calendar month.
  late final List<BudgetStatus> budgetStatuses = budgets
      .map((b) {
        final category = categoryById[b.categoryId];
        if (category == null) return null;
        final m = Dates.monthKeyNow();
        final spent = confirmed
            .where((t) =>
                t.type == TxnType.expense &&
                t.categoryId == b.categoryId &&
                Dates.monthKey(t.dateTime) == m)
            .fold(0.0, (s, t) => s + t.amount);
        return BudgetStatus(budget: b, category: category, spent: spent);
      })
      .whereType<BudgetStatus>()
      .toList();

  /// Net worth at the end of each of the last 6 months (the current month's
  /// point reflects today, not month-end) — see NetWorthHistory for how past
  /// points are reconstructed from existing records.
  late final List<NetWorthPoint> netWorthHistory = NetWorthHistory.monthly(
    accounts: accounts,
    confirmedTxns: confirmed,
    investments: investments,
    debts: debts,
  );

  late final List<SpendingInsight> spendingInsights =
      InsightGenerator.generate(confirmed, categoryById);

  /// Confirmed transactions as CSV rows (header first) — account/category
  /// ids resolved to their names, for opening in a spreadsheet app.
  List<List<String>> transactionCsvRows() {
    final sorted = confirmed.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return [
      ['Date', 'Type', 'Amount', 'Account', 'To account', 'Category', 'Merchant', 'Note', 'Source'],
      for (final t in sorted)
        [
          Dates.dateTime(t.dateTime),
          t.type.name,
          t.amount.toStringAsFixed(2),
          accountById[t.accountId]?.name ?? '',
          t.toAccountId != null ? (accountById[t.toAccountId]?.name ?? '') : '',
          t.categoryId != null ? (categoryById[t.categoryId]?.name ?? '') : '',
          t.merchant,
          t.note,
          t.source.name,
        ],
    ];
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);

class WalletNotifier extends AsyncNotifier<WalletData> {
  Repository get _repo => ref.read(repositoryProvider);
  Prefs get _prefs => ref.read(prefsProvider);
  NotificationService get _notifications => ref.read(notificationProvider);

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
      _repo.budgets(),
      _repo.savingsGoals(),
    ]);
    return WalletData(
      accounts: results[0] as List<Account>,
      categories: results[1] as List<Category>,
      txns: results[2] as List<Txn>,
      debts: results[3] as List<Debt>,
      investments: results[4] as List<Investment>,
      budgets: results[5] as List<Budget>,
      goals: results[6] as List<SavingsGoal>,
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _load());
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ── Accounts ──
  Future<void> saveAccount(Account a) async {
    final id = await _repo.upsertAccount(a);
    if (a.type == AccountType.creditCard && a.dueDay != null) {
      await _notifications.scheduleCardDue(id, a.name, a.dueDay!);
    } else {
      await _notifications.cancelCardDue(id);
    }
    await _refresh();
  }

  Future<void> deleteAccount(Account a) async {
    if (a.id != null) {
      await _repo.deleteAccount(a.id!);
      await _notifications.cancelCardDue(a.id!);
    }
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

  /// Save an edited/confirmed transaction. When it was a pending SMS capture,
  /// this also teaches its pattern what the right outcome was — whether that
  /// means "the guess was right" or "it should always be this instead" — so
  /// future messages like it get more confident over time.
  Future<void> confirmPendingTxn(Txn original, Txn edited) async {
    if (original.source == TxnSource.sms && (original.rawSms ?? '').isNotEmpty) {
      await _repo.recordPatternOutcome(
        SmsPattern.signatureOf(original.rawSms!),
        accountId: edited.accountId,
        categoryId: edited.categoryId,
        type: edited.type,
      );
    }
    await _repo.upsertTxn(edited.copyWith(status: TxnStatus.confirmed));
    await _refresh();
  }

  Future<void> deleteTxn(Txn t) async {
    if (t.id != null) await _repo.deleteTxn(t.id!);
    await _refresh();
  }

  /// Dismiss a pending SMS capture as not a real transaction (e.g. a
  /// promotional message that slipped through). Teaches its pattern to be
  /// ignored outright once this happens enough times.
  Future<void> dismissPending(Txn t) async {
    if (t.source == TxnSource.sms && (t.rawSms ?? '').isNotEmpty) {
      await _repo.recordPatternRejection(SmsPattern.signatureOf(t.rawSms!));
    }
    if (t.id != null) await _repo.deleteTxn(t.id!);
    await _refresh();
  }

  // ── Debts / lending ──
  Future<void> saveDebt(Debt d) async {
    await _repo.upsertDebt(d);
    await _refresh();
  }

  Future<void> deleteDebt(Debt d) async {
    if (d.id != null) {
      await _repo.deleteTxnsByDebt(d.id!); // remove principal + any repayment txns
      await _repo.deleteDebt(d.id!);
    }
    await _refresh();
  }

  /// Create or update a lending/borrowing entry. When [reflect] is true the
  /// principal is mirrored into [accountId] via a linked transaction that is
  /// kept in sync on every edit; when false, no account balance is touched.
  /// This keeps balances and stats correct whenever a due is changed.
  Future<void> saveDebtReflected(Debt input, bool reflect, int? accountId) async {
    // 1. Ensure the due row exists and get its id.
    final reflectAccount = reflect ? accountId : input.accountId;
    final debtId = await _repo.upsertDebt(input.copyWith(accountId: reflectAccount));
    final debt = input.copyWith(id: debtId);

    // 2. Reconcile the principal transaction that mirrors it into the account.
    final existingTxnId = input.principalTxnId;
    if (reflect && accountId != null && accountId > 0) {
      final isLent = debt.direction == DebtDirection.iLent;
      final type = isLent ? TxnType.expense : TxnType.income;
      final txnId = await _repo.upsertTxn(Txn(
        id: existingTxnId, // updates the existing entry, or inserts a new one
        type: type,
        amount: debt.amount,
        accountId: accountId,
        categoryId: await _repo.categoryIdByName(isLent ? Cats.lent : Cats.borrowed, type),
        note: (isLent ? 'Lent to ' : 'Borrowed from ') + debt.contactName,
        dateTime: debt.createdAt,
        contactName: debt.contactName,
        contactKey: debt.contactKey,
        debtId: debtId,
      ));
      await _repo.upsertDebt(
          debt.withLinks(id: debtId, accountId: accountId, principalTxnId: txnId));
    } else {
      if (existingTxnId != null) await _repo.deleteTxn(existingTxnId);
      await _repo.upsertDebt(
          debt.withLinks(id: debtId, accountId: debt.accountId, principalTxnId: null));
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

  // ── SMS capture ──
  bool _listening = false;

  /// Make sure SMS + notification permission is actually granted, every time
  /// the app opens — not just once. Requesting again when permission is
  /// already granted is a no-op (the OS returns immediately, no dialog), so
  /// this costs nothing for the common case, but it means a permission that
  /// was ever denied (or auto-revoked by Android for being unused) gets a
  /// real chance to be granted instead of silently staying broken forever.
  /// Old messages are excluded regardless, because [Prefs.lastSmsScan] is
  /// seeded to install time in main().
  Future<void> ensureSmsSetup() async {
    if (!_prefs.smsCapture) return;
    _prefs.smsPermGranted = await ref.read(smsServiceProvider).requestPermission();
    await ref.read(notificationProvider).requestPermission();
  }

  /// Start listening for incoming SMS — in real time while running, and via a
  /// background isolate (smsBackgroundHandler) when the app is closed/killed.
  void startSmsListener() {
    if (_listening || !_prefs.smsCapture) return;
    _listening = ref.read(smsServiceProvider).listenIncoming(
          (r) => _captureSms(r, notify: true),
          onBackground: smsBackgroundHandler,
        );
  }

  /// Catch up on any bank SMS that arrived (after install) while the app was
  /// closed. Never imports pre-install messages.
  Future<void> scanNewSms() async {
    if (!_prefs.smsCapture) return;
    final List<SmsRecord> records;
    try {
      records = await ref.read(smsServiceProvider).readInbox();
    } catch (_) {
      // Reading the inbox only fails like this when SMS permission isn't
      // actually granted — record that so Settings can surface it instead
      // of capture just silently doing nothing.
      _prefs.smsPermGranted = false;
      return;
    }
    final since = _prefs.lastSmsScan;
    final recent = records.where((r) => r.date > since).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final r in recent) {
      await _captureSms(r, notify: false, refresh: false);
    }
    await _refresh();
  }

  /// Parse a single SMS and, if it looks like a bank/UPI transaction, add it
  /// — auto-confirmed if its template is one we've learned to trust, pending
  /// your review otherwise (or skipped outright if we've learned it's noise).
  Future<void> _captureSms(SmsRecord r, {required bool notify, bool refresh = true}) async {
    if (r.date > _prefs.lastSmsScan) _prefs.lastSmsScan = r.date;
    final parsed = SmsParser.parse(r.body);
    if (parsed == null) return;
    if (parsed.ref != null && await _repo.upiRefExists(parsed.ref!)) return;

    final pattern = await _repo.getOrCreatePattern(SmsPattern.signatureOf(r.body), seenAt: r.date);
    if (pattern.alwaysIgnore) return;

    final accounts = state.value?.accounts ?? const <Account>[];
    final heuristicAccountId = SmsParser.matchAccountId(accounts, parsed);
    final learnedCategory = await _repo.lastCategoryForMerchant(parsed.merchant, parsed.type);
    final trusted = pattern.autoConfirm;

    await _repo.upsertTxn(Txn(
      type: trusted ? (pattern.lastType ?? parsed.type) : parsed.type,
      amount: parsed.amount,
      accountId: trusted ? (pattern.lastAccountId ?? heuristicAccountId) : heuristicAccountId,
      categoryId: trusted ? (pattern.lastCategoryId ?? learnedCategory) : learnedCategory,
      merchant: parsed.merchant,
      dateTime: r.date,
      source: TxnSource.sms,
      status: trusted ? TxnStatus.confirmed : TxnStatus.pending,
      upiRef: parsed.ref,
      rawSms: r.body,
    ));

    if (notify) {
      final credited = parsed.type == TxnType.income;
      final where = parsed.merchant.isNotEmpty ? ' · ${parsed.merchant}' : '';
      final amountText = '${credited ? '+' : '-'}₹${parsed.amount.toStringAsFixed(2)}$where';
      await ref.read(notificationProvider).showTxnDetected(
            credited ? 'Money received' : 'Money spent',
            trusted ? amountText : '$amountText — tap to confirm & categorize',
          );
    }
    if (refresh) await _refresh();
  }

  // ── Backup / restore ──
  Future<Map<String, dynamic>> exportData() => _repo.exportAll();

  Future<void> importData(Map<String, dynamic> data) async {
    await _repo.importAll(data);
    await _refresh();
  }

  // ── SMS pattern memory ──
  Future<List<SmsPattern>> loadPatterns() => _repo.allPatterns();
  Future<void> resetPattern(int id) => _repo.resetPattern(id);

  // ── Budgets ──
  Future<void> saveBudget(Budget b) async {
    await _repo.upsertBudget(b);
    await _refresh();
  }

  Future<void> deleteBudget(Budget b) async {
    if (b.id != null) await _repo.deleteBudget(b.id!);
    await _refresh();
  }

  // ── Savings goals ──
  Future<void> saveGoal(SavingsGoal g) async {
    await _repo.upsertSavingsGoal(g);
    await _refresh();
  }

  Future<void> deleteGoal(SavingsGoal g) async {
    if (g.id != null) await _repo.deleteSavingsGoal(g.id!);
    await _refresh();
  }

  /// Adds (or, with a negative amount, removes) money from a goal's running
  /// total. Never tied to any account/transaction — purely a motivational
  /// tracker toward the target.
  Future<void> contributeToGoal(SavingsGoal g, double delta) async {
    final newAmount = (g.savedAmount + delta).clamp(0.0, double.infinity);
    await _repo.upsertSavingsGoal(g.copyWith(savedAmount: newAmount));
    await _refresh();
  }
}
