import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(username, password);

      if (result['isAdmin'] == true || result['isActive'] == false) {
        _errorMessage = "Neuspješna prijava. Provjerite podatke ili kontaktirajte podršku.";
        notifyListeners();
        return false;
      }

      await fetchAndSetUser(result['id']);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = "Neuspješna prijava. Provjerite podatke.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAndSetUser(int userId) async {
    try {
      final userData = await ApiService.getUserById(userId);
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Greška pri učitavanju podataka korisnika.";
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.register(userData);
      await fetchAndSetUser(result['id']);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    _errorMessage = null;
    ApiService.logout();
    notifyListeners();
  }

  Future<bool> updateUser({
    required String email,
    required String firstName,
    required String lastName,
    required String? phoneNumber,
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
        phoneNumber: phoneNumber,
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

      final success = await ApiService.changePassword(
        userId: user!.id,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      notifyListeners();
      return success;
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
