import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../services/api_service.dart';

class CityProvider extends ChangeNotifier {
  List<City> _cities = [];
  City? _selectedCity;
  bool _isLoading = false;
  String? _errorMessage;

  List<City> get cities => _cities;
  City? get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getAllCities({int page = 1, int pageSize = 100}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getAllCities(
        page: page,
        pageSize: pageSize,
      );
      final resultsList = result['results'] as List? ?? [];

      _cities = resultsList
          .map((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<City>> searchCities({String? name}) async {
    try {
      final result = await ApiService.searchCities(name: name);
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<City?> getCityById(int cityId) async {
    try {
      final result = await ApiService.getCityById(cityId: cityId);
      _selectedCity = City.fromJson(result);
      notifyListeners();
      return _selectedCity;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<City?> createCity({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await ApiService.createCity(
        name: name,
        latitude: latitude,
        longitude: longitude,
      );
      final city = City.fromJson(result);
      _cities.insert(0, city);
      notifyListeners();
      return city;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<City?> updateCity({
    required int cityId,
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await ApiService.updateCity(
        cityId: cityId,
        name: name,
        latitude: latitude,
        longitude: longitude,
      );
      final updatedCity = City.fromJson(result);
      final index = _cities.indexWhere((city) => city.id == cityId);
      if (index != -1) {
        _cities[index] = updatedCity;
      }
      _selectedCity = updatedCity;
      notifyListeners();
      return updatedCity;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCity(int cityId) async {
    try {
      await ApiService.deleteCity(cityId);
      _cities.removeWhere((city) => city.id == cityId);
      if (_selectedCity?.id == cityId) {
        _selectedCity = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectCity(City city) {
    _selectedCity = city;
    notifyListeners();
  }

  City? findCityById(int cityId) {
    try {
      return _cities.firstWhere((city) => city.id == cityId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
