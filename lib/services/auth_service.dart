import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/account.dart';
import 'database_helper.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Check if username exists
      final existingUser = await _db.getUserByUsername(username);
      if (existingUser != null) {
        return {'success': false, 'message': 'Username already exists'};
      }

      // Check if email exists
      final existingEmail = await _db.getUserByEmail(email);
      if (existingEmail != null) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Create new user
      final uuid = const Uuid();
      final userId = uuid.v4();
      final now = DateTime.now();

      final user = User(
        id: userId,
        username: username,
        passwordHash: _hashPassword(password),
        email: email,
        displayName: displayName,
        createdAt: now,
        lastLogin: now,
      );

      await _db.createUser(user);

      // Create default account for user
      final defaultAccount = Account(
        id: uuid.v4(),
        userId: userId,
        name: 'Cash',
        type: 'cash',
        balance: 0.0,
        currency: 'BDT',
        createdAt: now,
        updatedAt: now,
      );
      await _db.createAccount(defaultAccount);

      // Create default categories
      await _db.createDefaultCategories(userId);

      _currentUser = user;
      return {
        'success': true,
        'message': 'Registration successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _db.getUserByUsername(username);

      if (user == null) {
        return {'success': false, 'message': 'User not found'};
      }

      if (user.passwordHash != _hashPassword(password)) {
        return {'success': false, 'message': 'Invalid password'};
      }

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _db.updateUser(updatedUser);

      _currentUser = updatedUser;
      return {
        'success': true,
        'message': 'Login successful',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  void logout() {
    _currentUser = null;
  }

  Future<bool> validatePassword(String password) async {
    if (_currentUser == null) return false;
    return _currentUser!.passwordHash == _hashPassword(password);
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    if (!await validatePassword(currentPassword)) {
      return {'success': false, 'message': 'Current password is incorrect'};
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        passwordHash: _hashPassword(newPassword),
      );
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to change password'};
    }
  }
}
