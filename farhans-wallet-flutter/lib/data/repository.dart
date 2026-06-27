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

  Future<bool> upiRefExists(String ref) async {
    final db = await _db;
    final rows = await db.query('transactions',
        columns: ['id'], where: 'upiRef = ?', whereArgs: [ref], limit: 1);
    return rows.isNotEmpty;
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
    };
  }

  /// Replaces all current data with the contents of a backup file.
  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final t in ['transactions', 'debts', 'investments', 'categories', 'accounts']) {
        await txn.delete(t);
      }
      for (final table in ['accounts', 'categories', 'transactions', 'debts', 'investments']) {
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
