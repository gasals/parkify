import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/preference_model.dart';
import '../models/request_models.dart';
import '../services/api_service.dart';

class PreferenceProvider extends ChangeNotifier {
  Preference? _userPreference;
  bool _isLoading = false;
  String? _errorMessage;

  Preference? get userPreference => _userPreference;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserPreference({required int userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userPreference = await ApiService.getUserPreference(userId: userId);
      notifyListeners();
    } catch (e) {
      log('PreferenceProvider.loadUserPreference error: $e');
      _errorMessage = ApiService.userFriendlyError(
        e,
        fallback: 'Došlo je do greške pri učitavanju postavki.',
      );
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFavoriteParking({
    required int userId,
    required int parkingZoneId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updateUserPreferences(
        userId: userId,
        request: PreferenceUpdateRequest(
          favoriteParkingZoneId: parkingZoneId,
        ),
      );
      _userPreference = result;
      notifyListeners();
    } catch (e) {
      log('PreferenceProvider.updateFavoriteParking error: $e');
      _errorMessage = ApiService.userFriendlyError(
        e,
        fallback: 'Došlo je do greške pri ažuriranju postavki.',
      );
      notifyListeners();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferredCity({
    required int userId,
    required int cityId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updateUserPreferences(
        userId: userId,
        request: PreferenceUpdateRequest(preferredCityId: cityId),
      );
      _userPreference = result;
      notifyListeners();
    } catch (e) {
      log('PreferenceProvider.updatePreferredCity error: $e');
      _errorMessage = ApiService.userFriendlyError(
        e,
        fallback: 'Došlo je do greške pri ažuriranju postavki.',
      );
      notifyListeners();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreference({
    required int userId,
    bool? prefersNearby,
    int? preferredCityId,
    int? favoriteParkingZoneId,
    bool? notifyAboutOffers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updateUserPreferences(
        userId: userId,
        request: PreferenceUpdateRequest(
          prefersNearby: prefersNearby,
          preferredCityId: preferredCityId,
          favoriteParkingZoneId: favoriteParkingZoneId,
          notifyAboutOffers: notifyAboutOffers,
        ),
      );
      _userPreference = result;
      notifyListeners();
    } catch (e) {
      log('PreferenceProvider.updatePreference error: $e');
      _errorMessage = ApiService.userFriendlyError(
        e,
        fallback: 'Došlo je do greške pri ažuriranju postavki.',
      );
      notifyListeners();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavoriteParking(int parkingZoneId) {
    return _userPreference?.favoriteParkingZoneId == parkingZoneId;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
