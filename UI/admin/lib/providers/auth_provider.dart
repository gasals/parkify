import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> adminLogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(username, password);

      _user = User.fromJson(result);
      _isAuthenticated = true;
      _errorMessage = null;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    ApiService.logout();
    notifyListeners();
  }

  Future<bool> updateUser({
    required String? email,
    required String? firstName,
    required String? lastName,
    required String? city,
    required String? address,
  }) async {
    if (user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.updateUser(
        userId: user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        address: address,
        city: city,
      );

      _user = User.fromJson(result);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String password,
    required String passwordConfirm,
  }) async {
    if (user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.changePassword(
        userId: user!.id,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
