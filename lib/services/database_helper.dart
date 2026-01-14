import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as models;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('xpensive.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        profile_photo TEXT,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // Account table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'BDT',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Category table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Transaction table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        is_recurring INTEGER DEFAULT 0,
        recurring_id TEXT,
        receipt_photo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  // User operations
  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Account operations
  Future<int> createAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAccountsByUserId(String userId) async {
    final db = await database;
    final maps = await db.query(
      'accounts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final db = await database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Category operations
  Future<int> createCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategoriesByUserId(String userId) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getCategoriesByType(String userId, String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type],
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction operations
  Future<int> createTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<models.Transaction>> getTransactionsByAccountId(
    String accountId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByUserId(
    String userId,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT t.* FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE a.user_id = ?
      ORDER BY t.date DESC
    ''',
      [userId],
    );
    return maps.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT t.* FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE a.user_id = ? AND t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC
    ''',
      [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return maps.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<models.Transaction?> getTransactionById(String id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return models.Transaction.fromMap(maps.first);
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Statistics
  Future<double> getTotalIncomeByUserId(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(t.amount) as total FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE a.user_id = ? AND t.type = 'income'
    ''',
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpenseByUserId(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(t.amount) as total FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE a.user_id = ? AND t.type = 'expense'
    ''',
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT c.name, SUM(t.amount) as total FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      INNER JOIN categories c ON t.category_id = c.id
      WHERE a.user_id = ? AND t.type = 'expense'
      GROUP BY c.id
    ''',
      [userId],
    );

    Map<String, double> expenses = {};
    for (var row in result) {
      expenses[row['name'] as String] = (row['total'] as num).toDouble();
    }
    return expenses;
  }

  Future<void> createDefaultCategories(String userId) async {
    final defaultCategories = [
      Category(
        id: '${userId}_food',
        userId: userId,
        name: 'Food & Dining',
        type: 'expense',
        color: '#FF5722',
        icon: 'restaurant',
      ),
      Category(
        id: '${userId}_transport',
        userId: userId,
        name: 'Transportation',
        type: 'expense',
        color: '#2196F3',
        icon: 'directions_car',
      ),
      Category(
        id: '${userId}_shopping',
        userId: userId,
        name: 'Shopping',
        type: 'expense',
        color: '#E91E63',
        icon: 'shopping_bag',
      ),
      Category(
        id: '${userId}_bills',
        userId: userId,
        name: 'Bills & Utilities',
        type: 'expense',
        color: '#9C27B0',
        icon: 'receipt',
      ),
      Category(
        id: '${userId}_entertainment',
        userId: userId,
        name: 'Entertainment',
        type: 'expense',
        color: '#00BCD4',
        icon: 'movie',
      ),
      Category(
        id: '${userId}_health',
        userId: userId,
        name: 'Health',
        type: 'expense',
        color: '#4CAF50',
        icon: 'local_hospital',
      ),
      Category(
        id: '${userId}_salary',
        userId: userId,
        name: 'Salary',
        type: 'income',
        color: '#8BC34A',
        icon: 'account_balance',
      ),
      Category(
        id: '${userId}_freelance',
        userId: userId,
        name: 'Freelance',
        type: 'income',
        color: '#CDDC39',
        icon: 'work',
      ),
      Category(
        id: '${userId}_investment',
        userId: userId,
        name: 'Investment',
        type: 'income',
        color: '#FFC107',
        icon: 'trending_up',
      ),
      Category(
        id: '${userId}_other_income',
        userId: userId,
        name: 'Other Income',
        type: 'income',
        color: '#FF9800',
        icon: 'attach_money',
      ),
    ];

    for (var category in defaultCategories) {
      await createCategory(category);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
