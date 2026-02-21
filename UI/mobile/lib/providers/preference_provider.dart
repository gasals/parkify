import 'package:flutter/material.dart';
import '../models/preference_model.dart';
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
      final result = await ApiService.getUserPreference(userId: userId);
      _userPreference = Preference.fromJson(result);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
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
      final updateData = {
        'favoriteParkingZoneId': parkingZoneId,
      };

      final result = await ApiService.updateUserPreferences(
        userId: userId,
        preferences: updateData,
      );

      _userPreference = Preference.fromJson(result);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
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
      final updateData = {
        'preferredCityId': cityId,
      };

      final result = await ApiService.updateUserPreferences(
        userId: userId,
        preferences: updateData,
      );

      _userPreference = Preference.fromJson(result);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreference({
    required int userId,
    bool? prefersCovered,
    bool? prefersNearby,
    int? preferredCityId,
    int? favoriteParkingZoneId,
    bool? notifyAboutOffers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      
      if (prefersCovered != null) data['prefersCovered'] = prefersCovered;
      if (prefersNearby != null) data['prefersNearby'] = prefersNearby;
      if (preferredCityId != null) data['preferredCityId'] = preferredCityId;
      if (favoriteParkingZoneId != null) data['favoriteParkingZoneId'] = favoriteParkingZoneId;
      if (notifyAboutOffers != null) data['notifyAboutOffers'] = notifyAboutOffers;

      final result = await ApiService.updateUserPreferences(
        userId: userId,
        preferences: data,
      );

      _userPreference = Preference.fromJson(result);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavoriteParking(int parkingZoneId) {
    return _userPreference?.favoriteParkingZoneId == parkingZoneId;
  }
}
