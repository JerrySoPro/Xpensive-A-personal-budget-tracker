import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as models;

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _accountsCollection =>
      _firestore.collection('accounts');
  CollectionReference get _categoriesCollection =>
      _firestore.collection('categories');
  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');

  // Current Firebase User
  fb_auth.User? get currentFirebaseUser => _auth.currentUser;

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      // Check if username is already taken
      final usernameQuery = await _usersCollection
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return {'success': false, 'message': 'Username already exists'};
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;
      final now = DateTime.now();

      // Create user document in Firestore
      final user = User(
        id: userId,
        username: username,
        passwordHash: '', // Not needed with Firebase Auth
        email: email,
        displayName: displayName,
        createdAt: now,
        lastLogin: now,
      );

      await _usersCollection.doc(userId).set(user.toMap());

      // Create default account
      final defaultAccount = Account(
        id: '${userId}_cash',
        userId: userId,
        name: 'Cash',
        type: 'cash',
        balance: 0.0,
        currency: 'BDT',
        createdAt: now,
        updatedAt: now,
      );
      await _accountsCollection
          .doc(defaultAccount.id)
          .set(defaultAccount.toMap());

      // Create default categories
      await _createDefaultCategories(userId);

      return {
        'success': true,
        'message': 'Registration successful',
        'user': user,
      };
    } on fb_auth.FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'The password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // Update last login
      await _usersCollection.doc(userId).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });

      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User data not found'};
      }

      final user = User.fromMap(userDoc.data() as Map<String, dynamic>);

      return {'success': true, 'message': 'Login successful', 'user': user};
    } on fb_auth.FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
    if (!userDoc.exists) return null;

    return User.fromMap(userDoc.data() as Map<String, dynamic>);
  }

  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? profilePhoto,
  }) async {
    final Map<String, dynamic> updates = {};

    if (displayName != null) {
      updates['displayName'] = displayName;
    }
    if (profilePhoto != null) {
      updates['profilePhoto'] = profilePhoto;
    }

    if (updates.isNotEmpty) {
      await _usersCollection.doc(userId).update(updates);
    }
  }

  // ==================== ACCOUNTS ====================

  Future<void> createAccount(Account account) async {
    await _accountsCollection.doc(account.id).set(account.toMap());
  }

  Future<List<Account>> getAccountsByUserId(String userId) async {
    final snapshot = await _accountsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final accounts = snapshot.docs
        .map((doc) => Account.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Sort by createdAt descending in Dart
    accounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return accounts;
  }

  Future<void> updateAccount(Account account) async {
    await _accountsCollection.doc(account.id).update(account.toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    await _accountsCollection.doc(accountId).delete();
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    await _accountsCollection.doc(accountId).update({
      'balance': newBalance,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ==================== CATEGORIES ====================

  Future<void> createCategory(Category category) async {
    await _categoriesCollection.doc(category.id).set(category.toMap());
  }

  Future<List<Category>> getCategoriesByUserId(String userId) async {
    final snapshot = await _categoriesCollection
        .where('userId', isEqualTo: userId)
        .get();

    final categories = snapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Sort by name in Dart
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Future<List<Category>> getCategoriesByType(String userId, String type) async {
    final snapshot = await _categoriesCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .get();

    final categories = snapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Sort by name in Dart
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Future<void> updateCategory(Category category) async {
    await _categoriesCollection.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCollection.doc(categoryId).delete();
  }

  Future<void> _createDefaultCategories(String userId) async {
    final now = DateTime.now();
    final defaultCategories = [
      // Income categories
      Category(
        id: '${userId}_salary',
        userId: userId,
        name: 'Salary',
        type: 'income',
        icon: 'work',
        color: '#4CAF50',
        createdAt: now,
      ),
      Category(
        id: '${userId}_freelance',
        userId: userId,
        name: 'Freelance',
        type: 'income',
        icon: 'computer',
        color: '#2196F3',
        createdAt: now,
      ),
      Category(
        id: '${userId}_investment',
        userId: userId,
        name: 'Investment',
        type: 'income',
        icon: 'trending_up',
        color: '#9C27B0',
        createdAt: now,
      ),
      Category(
        id: '${userId}_gift',
        userId: userId,
        name: 'Gift',
        type: 'income',
        icon: 'card_giftcard',
        color: '#E91E63',
        createdAt: now,
      ),
      // Expense categories
      Category(
        id: '${userId}_food',
        userId: userId,
        name: 'Food & Dining',
        type: 'expense',
        icon: 'restaurant',
        color: '#FF5722',
        createdAt: now,
      ),
      Category(
        id: '${userId}_transport',
        userId: userId,
        name: 'Transportation',
        type: 'expense',
        icon: 'directions_car',
        color: '#795548',
        createdAt: now,
      ),
      Category(
        id: '${userId}_shopping',
        userId: userId,
        name: 'Shopping',
        type: 'expense',
        icon: 'shopping_bag',
        color: '#FF9800',
        createdAt: now,
      ),
      Category(
        id: '${userId}_utilities',
        userId: userId,
        name: 'Utilities',
        type: 'expense',
        icon: 'power',
        color: '#607D8B',
        createdAt: now,
      ),
      Category(
        id: '${userId}_entertainment',
        userId: userId,
        name: 'Entertainment',
        type: 'expense',
        icon: 'movie',
        color: '#673AB7',
        createdAt: now,
      ),
      Category(
        id: '${userId}_health',
        userId: userId,
        name: 'Health',
        type: 'expense',
        icon: 'local_hospital',
        color: '#F44336',
        createdAt: now,
      ),
      Category(
        id: '${userId}_education',
        userId: userId,
        name: 'Education',
        type: 'expense',
        icon: 'school',
        color: '#3F51B5',
        createdAt: now,
      ),
      Category(
        id: '${userId}_other',
        userId: userId,
        name: 'Other',
        type: 'expense',
        icon: 'more_horiz',
        color: '#9E9E9E',
        createdAt: now,
      ),
    ];

    for (final category in defaultCategories) {
      await _categoriesCollection.doc(category.id).set(category.toMap());
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<void> createTransaction(models.Transaction transaction) async {
    await _transactionsCollection.doc(transaction.id).set(transaction.toMap());
  }

  Future<List<models.Transaction>> getTransactionsByUserId(
    String userId,
  ) async {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map(
          (doc) =>
              models.Transaction.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();

    // Sort by date descending in Dart
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<List<models.Transaction>> getTransactionsByAccount(
    String accountId,
  ) async {
    final snapshot = await _transactionsCollection
        .where('accountId', isEqualTo: accountId)
        .get();

    final transactions = snapshot.docs
        .map(
          (doc) =>
              models.Transaction.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();

    // Sort by date descending in Dart
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<List<models.Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map(
          (doc) =>
              models.Transaction.fromMap(doc.data() as Map<String, dynamic>),
        )
        .where(
          (t) =>
              t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();

    // Sort by date descending in Dart
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    await _transactionsCollection
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsCollection.doc(transactionId).delete();
  }

  // ==================== STATISTICS ====================

  Future<Map<String, double>> getExpensesByCategory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense');

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }

    final snapshot = await query.get();
    final Map<String, double> categoryTotals = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final categoryId = data['categoryId'] as String;
      final amount = (data['amount'] as num).toDouble();

      categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
    }

    return categoryTotals;
  }

  Future<double> getTotalIncome(String userId) async {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'income')
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> getTotalExpense(String userId) async {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense')
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num).toDouble();
    }
    return total;
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final doc = await _categoriesCollection.doc(categoryId).get();
    if (!doc.exists) return null;
    return Category.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Get account by ID
  Future<Account?> getAccountById(String accountId) async {
    final doc = await _accountsCollection.doc(accountId).get();
    if (!doc.exists) return null;
    return Account.fromMap(doc.data() as Map<String, dynamic>);
  }
}
