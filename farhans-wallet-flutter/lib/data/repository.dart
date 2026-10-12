import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'models.dart';

class Repository {
  final AppDatabase _appDb;
  Repository(this._appDb);

  Future<Database> get _db async => _appDb.database;

  // ───────────────────────── Reads ─────────────────────────
  Future<List<Account>> accounts({bool includeArchived = false}) async {
    final db = await _db;
    final rows = await db.query(
      'accounts',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sortOrder, id',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Category>> categories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'sortOrder, name');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Txn>> transactions() async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'dateTime DESC');
    return rows.map(Txn.fromMap).toList();
  }

  Future<List<Debt>> debts() async {
    final db = await _db;
    final rows = await db.query('debts', orderBy: 'settled, createdAt DESC');
    return rows.map(Debt.fromMap).toList();
  }

  Future<List<Investment>> investments() async {
    final db = await _db;
    final rows = await db.query('investments', orderBy: 'sold, createdAt DESC');
    return rows.map(Investment.fromMap).toList();
  }

  // ───────────────────────── Writes ─────────────────────────
  Future<int> upsertAccount(Account a) async {
    final db = await _db;
    if (a.id == null) return db.insert('accounts', a.toMap()..remove('id'));
    await db.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
    return a.id!;
  }

  Future<void> deleteAccount(int id) async {
    final db = await _db;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> upsertCategory(Category c) async {
    final db = await _db;
    if (c.id == null) return db.insert('categories', c.toMap()..remove('id'));
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    return c.id!;
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> upsertTxn(Txn t) async {
    final db = await _db;
    if (t.id == null) return db.insert('transactions', t.toMap()..remove('id'));
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    return t.id!;
  }

  Future<void> deleteTxn(int id) async {
    final db = await _db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> upsertDebt(Debt d) async {
    final db = await _db;
    if (d.id == null) return db.insert('debts', d.toMap()..remove('id'));
    await db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
    return d.id!;
  }

  Future<void> deleteDebt(int id) async {
    final db = await _db;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTxnsByDebt(int debtId) async {
    final db = await _db;
    await db.delete('transactions', where: 'debtId = ?', whereArgs: [debtId]);
  }

  Future<int> upsertInvestment(Investment i) async {
    final db = await _db;
    if (i.id == null) return db.insert('investments', i.toMap()..remove('id'));
    await db.update('investments', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
    return i.id!;
  }

  Future<void> deleteInvestment(int id) async {
    final db = await _db;
    await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int?> categoryIdByName(String name, TxnType type) async {
    final db = await _db;
    final rows = await db.query('categories',
        columns: ['id'], where: 'name = ? AND type = ?', whereArgs: [name, type.name], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// The category most recently used for a transaction at this merchant, if
  /// any — lets newly-captured SMS transactions be auto-categorized the way
  /// the user categorized this merchant before, instead of always landing
  /// uncategorized.
  Future<int?> lastCategoryForMerchant(String merchant, TxnType type) async {
    if (merchant.trim().isEmpty) return null;
    final db = await _db;
    final rows = await db.query(
      'transactions',
      columns: ['categoryId'],
      where: 'LOWER(merchant) = ? AND type = ? AND categoryId IS NOT NULL',
      whereArgs: [merchant.trim().toLowerCase(), type.name],
      orderBy: 'dateTime DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['categoryId'] as int?;
  }

  Future<bool> upiRefExists(String ref) async {
    final db = await _db;
    final rows = await db.query('transactions',
        columns: ['id'], where: 'upiRef = ?', whereArgs: [ref], limit: 1);
    return rows.isNotEmpty;
  }

  // ───────────────────────── SMS pattern learning ─────────────────────────
  // Not included in backup/restore: it's a local learning cache, not
  // user-authored data, and safely rebuilds itself from new confirmations.

  /// Looks up the learned record for this message template, creating one
  /// (and counting this sighting) if it's never been seen before.
  Future<SmsPattern> getOrCreatePattern(String signature, {required int seenAt}) async {
    final db = await _db;
    final rows =
        await db.query('sms_patterns', where: 'signature = ?', whereArgs: [signature], limit: 1);
    if (rows.isEmpty) {
      final id = await db.insert('sms_patterns', {
        'signature': signature,
        'timesSeen': 1,
        'consistentStreak': 0,
        'timesRejected': 0,
        'lastAccountId': null,
        'lastCategoryId': null,
        'lastType': null,
        'autoConfirm': 0,
        'alwaysIgnore': 0,
        'firstSeenAt': seenAt,
        'lastSeenAt': seenAt,
      });
      return SmsPattern(
        id: id,
        signature: signature,
        timesSeen: 1,
        consistentStreak: 0,
        timesRejected: 0,
        autoConfirm: false,
        alwaysIgnore: false,
        firstSeenAt: seenAt,
        lastSeenAt: seenAt,
      );
    }
    final existing = SmsPattern.fromMap(rows.first);
    await db.update(
      'sms_patterns',
      {'timesSeen': existing.timesSeen + 1, 'lastSeenAt': seenAt},
      where: 'signature = ?',
      whereArgs: [signature],
    );
    return existing;
  }

  /// Records what the user actually saved for a message matching this
  /// pattern. A streak of identical outcomes (whether that's confirming the
  /// guess as-is, or correcting it to the same thing every time) is what
  /// builds trust — not a single lucky confirmation.
  Future<void> recordPatternOutcome(
    String signature, {
    required int accountId,
    int? categoryId,
    required TxnType type,
  }) async {
    final db = await _db;
    final rows =
        await db.query('sms_patterns', where: 'signature = ?', whereArgs: [signature], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final sameAsLast = row['lastAccountId'] == accountId &&
        row['lastCategoryId'] == categoryId &&
        row['lastType'] == type.name;
    final newStreak = sameAsLast ? (row['consistentStreak'] as int? ?? 0) + 1 : 1;
    await db.update(
      'sms_patterns',
      {
        'lastAccountId': accountId,
        'lastCategoryId': categoryId,
        'lastType': type.name,
        'consistentStreak': newStreak,
        'autoConfirm': newStreak >= SmsPattern.autoConfirmStreak ? 1 : 0,
        'timesRejected': 0,
        'alwaysIgnore': 0,
      },
      where: 'signature = ?',
      whereArgs: [signature],
    );
  }

  /// Records that a message matching this pattern was dismissed/deleted as
  /// not a real transaction. Enough of these and it's ignored outright —
  /// personalizing the promo/noise filter to the user's actual senders.
  Future<void> recordPatternRejection(String signature) async {
    final db = await _db;
    final rows = await db.query('sms_patterns',
        columns: ['timesRejected'], where: 'signature = ?', whereArgs: [signature], limit: 1);
    if (rows.isEmpty) return;
    final newCount = (rows.first['timesRejected'] as int? ?? 0) + 1;
    await db.update(
      'sms_patterns',
      {
        'timesRejected': newCount,
        'alwaysIgnore': newCount >= SmsPattern.autoRejectCount ? 1 : 0,
        'autoConfirm': 0,
        'consistentStreak': 0,
      },
      where: 'signature = ?',
      whereArgs: [signature],
    );
  }

  /// All learned message-template patterns, most recently seen first — for
  /// a Settings screen that shows what's trusted/ignored and lets the user
  /// reset one that learned the wrong thing.
  Future<List<SmsPattern>> allPatterns() async {
    final db = await _db;
    final rows = await db.query('sms_patterns', orderBy: 'lastSeenAt DESC');
    return rows.map(SmsPattern.fromMap).toList();
  }

  /// Forgets everything learned about one pattern — it starts over as a
  /// brand-new, untrusted template next time a matching message arrives.
  Future<void> resetPattern(int id) async {
    final db = await _db;
    await db.delete('sms_patterns', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── Budgets ─────────────────────────
  Future<List<Budget>> budgets() async {
    final db = await _db;
    final rows = await db.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<int> upsertBudget(Budget b) async {
    final db = await _db;
    if (b.id == null) {
      return db.insert('budgets', b.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
    return b.id!;
  }

  Future<void> deleteBudget(int id) async {
    final db = await _db;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── Savings goals ─────────────────────────
  Future<List<SavingsGoal>> savingsGoals() async {
    final db = await _db;
    final rows = await db.query('savings_goals', orderBy: 'createdAt DESC');
    return rows.map(SavingsGoal.fromMap).toList();
  }

  Future<int> upsertSavingsGoal(SavingsGoal g) async {
    final db = await _db;
    if (g.id == null) return db.insert('savings_goals', g.toMap()..remove('id'));
    await db.update('savings_goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
    return g.id!;
  }

  Future<void> deleteSavingsGoal(int id) async {
    final db = await _db;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── Backup / restore ─────────────────────────
  Future<Map<String, dynamic>> exportAll() async {
    final db = await _db;
    return {
      'app': 'pocket_flow',
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'accounts': await db.query('accounts'),
      'categories': await db.query('categories'),
      'transactions': await db.query('transactions'),
      'debts': await db.query('debts'),
      'investments': await db.query('investments'),
      'budgets': await db.query('budgets'),
      'savings_goals': await db.query('savings_goals'),
    };
  }

  /// Replaces all current data with the contents of a backup file.
  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final t in [
        'transactions',
        'debts',
        'investments',
        'categories',
        'accounts',
        'budgets',
        'savings_goals',
      ]) {
        await txn.delete(t);
      }
      for (final table in [
        'accounts',
        'categories',
        'transactions',
        'debts',
        'investments',
        'budgets',
        'savings_goals',
      ]) {
        final rows = (data[table] as List?) ?? const [];
        for (final row in rows) {
          await txn.insert(table, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Live balance for one account. For credit cards the balance represents the
  /// amount OWED (outstanding): spending/lending raises it, payments reduce it.
  static double computeBalance(Account account, List<Txn> txns) {
    final card = account.type == AccountType.creditCard;
    var bal = account.openingBalance;
    for (final t in txns) {
      if (t.status != TxnStatus.confirmed) continue;
      switch (t.type) {
        case TxnType.income:
          if (t.accountId == account.id) bal += card ? -t.amount : t.amount;
          break;
        case TxnType.expense:
          if (t.accountId == account.id) bal += card ? t.amount : -t.amount;
          break;
        case TxnType.transfer:
          if (t.accountId == account.id) bal += card ? t.amount : -t.amount;
          if (t.toAccountId == account.id) bal += card ? -t.amount : t.amount;
          break;
      }
    }
    return bal;
  }
}
