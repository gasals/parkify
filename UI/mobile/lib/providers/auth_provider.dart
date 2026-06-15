import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/request_models.dart';
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

  String _messageFromError(Object error, String fallback) {
    return ApiService.userFriendlyError(error, fallback: fallback);
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(username, password);

      if (result.isAdmin || !result.isActive) {
        _errorMessage =
            "Neuspješna prijava. Provjerite podatke ili kontaktirajte podršku.";
        notifyListeners();
        return false;
      }

      await fetchAndSetUser(result.id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _messageFromError(
        e,
        "Neuspješna prijava. Provjerite podatke.",
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAndSetUser(int userId) async {
    try {
      _user = await ApiService.getUserById(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = _messageFromError(
        e,
        "Greška pri učitavanju podataka korisnika.",
      );
    }
  }

  Future<bool> register(UserRegistrationRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.register(request);
      await fetchAndSetUser(result.id);
      _errorMessage = null;
      return true;
    } catch (e) {
      log('AuthProvider.register error: $e');
      _errorMessage = _messageFromError(
        e,
        'Neuspješna registracija. Pokušajte ponovno.',
      );
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

      _user = await ApiService.updateUser(
        userId: user!.id,
        request: UserUpdateRequestDto(
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      log('AuthProvider.updateUser error: $e');
      _errorMessage = _messageFromError(
        e,
        'Došlo je do greške pri ažuriranju korisnika.',
      );
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirm,
  }) async {
    if (user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final success = await ApiService.changePassword(
        userId: user!.id,
        request: ChangePasswordRequestDto(
          currentPassword: currentPassword,
          password: password,
          passwordConfirm: passwordConfirm,
        ),
      );

      notifyListeners();
      return success;
    } catch (e) {
      log('AuthProvider.changePassword error: $e');
      _errorMessage = _messageFromError(
        e,
        'Došlo je do greške pri promjeni lozinke.',
      );
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
