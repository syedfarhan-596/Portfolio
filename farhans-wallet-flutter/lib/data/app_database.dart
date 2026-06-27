import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Centralised category names used by automated flows.
class Cats {
  static const repayment = 'Refund / Repayment';
  static const settlement = 'Debt Settlement';
  static const cardPayment = 'Credit Card Payment';
  static const cardPoints = 'Card Points Redeemed';
  static const investment = 'Investments';
  static const investReturn = 'Investment Returns';
  static const lent = 'Money Lent';
  static const borrowed = 'Money Borrowed';
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'farhans_wallet.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        openingBalance REAL NOT NULL DEFAULT 0,
        colorHex TEXT NOT NULL,
        icon TEXT NOT NULL,
        creditLimit REAL,
        includeInTotal INTEGER NOT NULL DEFAULT 1,
        archived INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        isDefault INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        accountId INTEGER NOT NULL,
        toAccountId INTEGER,
        categoryId INTEGER,
        note TEXT NOT NULL DEFAULT '',
        merchant TEXT NOT NULL DEFAULT '',
        dateTime INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        status TEXT NOT NULL DEFAULT 'confirmed',
        contactName TEXT,
        contactKey TEXT,
        upiRef TEXT,
        rawSms TEXT,
        debtId INTEGER
      )''');
    await db.execute('CREATE INDEX idx_txn_date ON transactions(dateTime)');
    await db.execute('CREATE INDEX idx_txn_status ON transactions(status)');
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contactName TEXT NOT NULL,
        contactKey TEXT,
        direction TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        createdAt INTEGER NOT NULL,
        dueAfterSalary INTEGER NOT NULL DEFAULT 0,
        settled INTEGER NOT NULL DEFAULT 0,
        settledAt INTEGER,
        accountId INTEGER
      )''');
    await db.execute('''
      CREATE TABLE investments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        investedAmount REAL NOT NULL,
        currentValue REAL,
        accountId INTEGER,
        createdAt INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        sold INTEGER NOT NULL DEFAULT 0
      )''');
  }

  Future<void> _seed(Database db) async {
    final accounts = <Account>[
      const Account(name: 'Bank 1', type: AccountType.bank, colorHex: '#0984E3', icon: 'account_balance', sortOrder: 0),
      const Account(name: 'Bank 2', type: AccountType.bank, colorHex: '#00B894', icon: 'account_balance', sortOrder: 1),
      const Account(name: 'Bank 3', type: AccountType.bank, colorHex: '#6C5CE7', icon: 'account_balance', sortOrder: 2),
      const Account(name: 'Cash', type: AccountType.cash, colorHex: '#FDCB6E', icon: 'payments', sortOrder: 3),
      const Account(name: 'SBI PhonePe Credit Card', type: AccountType.creditCard, colorHex: '#E17055', icon: 'credit_card', includeInTotal: false, sortOrder: 4),
    ];
    for (final a in accounts) {
      await db.insert('accounts', a.toMap()..remove('id'));
    }
    for (final c in defaultCategories) {
      await db.insert('categories', c.toMap()..remove('id'));
    }
  }

  /// Insert any default categories missing by name (covers fresh installs).
  Future<void> ensureDefaultCategories(Database db) async {
    final rows = await db.query('categories', columns: ['name']);
    final existing = rows.map((e) => e['name'] as String).toSet();
    for (final c in defaultCategories) {
      if (!existing.contains(c.name)) {
        await db.insert('categories', c.toMap()..remove('id'));
      }
    }
  }

  static const List<Category> defaultCategories = [
    Category(name: 'Food', type: TxnType.expense, icon: 'restaurant', colorHex: '#E17055', isDefault: true, sortOrder: 0),
    Category(name: 'Groceries', type: TxnType.expense, icon: 'shopping_cart', colorHex: '#00CEC9', isDefault: true, sortOrder: 1),
    Category(name: 'Clothing', type: TxnType.expense, icon: 'checkroom', colorHex: '#0984E3', isDefault: true, sortOrder: 2),
    Category(name: 'Family', type: TxnType.expense, icon: 'family', colorHex: '#00B894', isDefault: true, sortOrder: 3),
    Category(name: 'Friends / Outing', type: TxnType.expense, icon: 'groups', colorHex: '#6C5CE7', isDefault: true, sortOrder: 4),
    Category(name: 'Transport', type: TxnType.expense, icon: 'directions_car', colorHex: '#FDCB6E', isDefault: true, sortOrder: 5),
    Category(name: 'Fuel', type: TxnType.expense, icon: 'fuel', colorHex: '#D63031', isDefault: true, sortOrder: 6),
    Category(name: 'Travel', type: TxnType.expense, icon: 'flight', colorHex: '#0984E3', isDefault: true, sortOrder: 7),
    Category(name: 'Bills & Utilities', type: TxnType.expense, icon: 'receipt', colorHex: '#D63031', isDefault: true, sortOrder: 8),
    Category(name: 'Rent', type: TxnType.expense, icon: 'home', colorHex: '#E17055', isDefault: true, sortOrder: 9),
    Category(name: 'Shopping', type: TxnType.expense, icon: 'shopping_bag', colorHex: '#E84393', isDefault: true, sortOrder: 10),
    Category(name: 'Health', type: TxnType.expense, icon: 'health', colorHex: '#FF7675', isDefault: true, sortOrder: 11),
    Category(name: 'Entertainment', type: TxnType.expense, icon: 'movie', colorHex: '#A29BFE', isDefault: true, sortOrder: 12),
    Category(name: 'Subscriptions', type: TxnType.expense, icon: 'subscriptions', colorHex: '#6C5CE7', isDefault: true, sortOrder: 13),
    Category(name: 'Education', type: TxnType.expense, icon: 'school', colorHex: '#0984E3', isDefault: true, sortOrder: 14),
    Category(name: 'Personal Care', type: TxnType.expense, icon: 'spa', colorHex: '#E84393', isDefault: true, sortOrder: 15),
    Category(name: 'Gifts & Donations', type: TxnType.expense, icon: 'gift', colorHex: '#FAB1A0', isDefault: true, sortOrder: 16),
    Category(name: 'EMI & Loans', type: TxnType.expense, icon: 'savings', colorHex: '#636E72', isDefault: true, sortOrder: 17),
    Category(name: 'Insurance', type: TxnType.expense, icon: 'shield', colorHex: '#00B894', isDefault: true, sortOrder: 18),
    Category(name: 'Pets', type: TxnType.expense, icon: 'pets', colorHex: '#FDCB6E', isDefault: true, sortOrder: 19),
    Category(name: 'Sports & Fitness', type: TxnType.expense, icon: 'sports', colorHex: '#00CEC9', isDefault: true, sortOrder: 20),
    Category(name: Cats.investment, type: TxnType.expense, icon: 'trending_up', colorHex: '#1AAD7E', isDefault: true, sortOrder: 21),
    Category(name: Cats.cardPayment, type: TxnType.expense, icon: 'credit_card', colorHex: '#E17055', isDefault: true, sortOrder: 22),
    Category(name: Cats.settlement, type: TxnType.expense, icon: 'handshake', colorHex: '#A29BFE', isDefault: true, sortOrder: 23),
    Category(name: Cats.lent, type: TxnType.expense, icon: 'handshake', colorHex: '#0984E3', isDefault: true, sortOrder: 24),
    Category(name: 'Other', type: TxnType.expense, icon: 'category', colorHex: '#636E72', isDefault: true, sortOrder: 25),
    Category(name: 'Salary', type: TxnType.income, icon: 'payments', colorHex: '#00B894', isDefault: true, sortOrder: 0),
    Category(name: 'Business', type: TxnType.income, icon: 'store', colorHex: '#0984E3', isDefault: true, sortOrder: 1),
    Category(name: 'Freelance', type: TxnType.income, icon: 'work', colorHex: '#6C5CE7', isDefault: true, sortOrder: 2),
    Category(name: Cats.repayment, type: TxnType.income, icon: 'undo', colorHex: '#0984E3', isDefault: true, sortOrder: 3),
    Category(name: 'Cashback / Rewards', type: TxnType.income, icon: 'gift', colorHex: '#6C5CE7', isDefault: true, sortOrder: 4),
    Category(name: Cats.cardPoints, type: TxnType.income, icon: 'star', colorHex: '#FDCB6E', isDefault: true, sortOrder: 5),
    Category(name: Cats.investReturn, type: TxnType.income, icon: 'trending_up', colorHex: '#1AAD7E', isDefault: true, sortOrder: 6),
    Category(name: Cats.borrowed, type: TxnType.income, icon: 'handshake', colorHex: '#FDCB6E', isDefault: true, sortOrder: 7),
    Category(name: 'Interest', type: TxnType.income, icon: 'savings', colorHex: '#00CEC9', isDefault: true, sortOrder: 8),
    Category(name: 'Other Income', type: TxnType.income, icon: 'category', colorHex: '#636E72', isDefault: true, sortOrder: 9),
  ];
}
