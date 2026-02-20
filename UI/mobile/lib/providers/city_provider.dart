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
      final result = await ApiService.getAllCities(page: page, pageSize: pageSize);
      
      final resultsList = result['results'] as List? ?? [];
      final citiesList = resultsList
          .map((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();
      
      _cities = citiesList;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

  City? findCityByName(String name) {
    try {
      return _cities.firstWhere((city) => city.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}