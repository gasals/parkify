import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  Future<void> searchUsers({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int page = 1,
    int pageSize = 20,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.searchUsers(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        page: page,
        pageSize: pageSize,
      );

      final resultsList = result['results'] as List? ?? [];

      if (page == 1) {
        _users = [];
      }

      _users.addAll(
        resultsList
            .map((user) => User.fromJson(user as Map<String, dynamic>))
            .toList(),
      );

      _totalCount = result['count'] ?? 0;
      _currentPage = page;
      _totalPages = (_totalCount / pageSize).ceil();

      notifyListeners();
    } catch (e) {
      log('Admin UserProvider.searchUsers error: $e');
      _errorMessage = 'Došlo je do greške pri pretrazi korisnika.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
    String? address,
    String? city,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.createUser(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
        address: address,
        city: city,
      );

      final newUser = User.fromJson(result);
      _users.insert(0, newUser);

      notifyListeners();
      return true;
    } catch (e) {
      log('Admin UserProvider.createUser error: $e');
      _errorMessage = 'Došlo je do greške pri kreiranju korisnika.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    required String? address,
    required String? city,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.updateUser(
        userId: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        address: address,
        city: city,
      );

      final updatedUser = User.fromJson(result);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      notifyListeners();
      return true;
    } catch (e) {
      log('Admin UserProvider.updateUser error: $e');
      _errorMessage = 'Došlo je do greške pri ažuriranju korisnika.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserActive({
    required int userId,
    required bool isActive,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.toggleUserActive(
        userId: userId,
        isActive: isActive,
      );

      final updatedUser = User.fromJson(result);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      notifyListeners();
      return true;
    } catch (e) {
      log('Admin UserProvider.toggleUserActive error: $e');
      _errorMessage = 'Došlo je do greške pri promjeni statusa korisnika.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<User>> getAllUsersList({int pageSize = 1000}) async {
    try {
      final result = await ApiService.getAllUsers(pageSize: pageSize);
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Admin UserProvider.getAllUsersList error: $e');
      _errorMessage = 'Došlo je do greške pri preuzimanju korisnika.';
      return [];
    }
  }

  Future<List<User>> searchUsersLive({String? username, String? email}) async {
    try {
      final result = await ApiService.searchUsers(
        username: username,
        email: email,
        pageSize: 1000,
      );
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Admin UserProvider.searchUsersLive error: $e');
      _errorMessage = 'Došlo je do greške pri pretrazi korisnika.';
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
