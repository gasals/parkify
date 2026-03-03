import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../models/parking_zone_model.dart';
import '../services/api_service.dart';

class ParkingZoneProvider extends ChangeNotifier {
  List<ParkingZone> _parkingZones = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  List<ParkingZone> get parkingZones => _parkingZones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  Future<void> searchParkingZones({
    String? name,
    int? cityId,
    int page = 1,
    int pageSize = 20,
    bool includeSpots = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.searchParkingZones(
        name: name,
        cityId: cityId,
        page: page,
        pageSize: pageSize,
        includeSpots: includeSpots,
      );

      final resultsList = result['results'] as List? ?? [];

      if (page == 1) {
        _parkingZones = [];
      }

      _parkingZones.addAll(
        resultsList
            .map((zone) => ParkingZone.fromJson(zone as Map<String, dynamic>))
            .toList(),
      );

      _totalCount = result['count'] ?? 0;
      _currentPage = page;
      _totalPages = (_totalCount / pageSize).ceil();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createParkingZone({
    required String name,
    required String description,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required double pricePerHour,
    double? dailyRate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.createParkingZone(
        name: name,
        description: description,
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
        pricePerHour: pricePerHour,
        dailyRate: dailyRate,
      );

      final newZone = ParkingZone.fromJson(result);
      _parkingZones.insert(0, newZone);

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

  Future<bool> updateParkingZone({
    required int zoneId,
    String? name,
    String? description,
    String? address,
    double? pricePerHour,
    double? dailyRate,
    bool? isActive,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.updateParkingZone(
        zoneId: zoneId,
        name: name,
        description: description,
        address: address,
        pricePerHour: pricePerHour,
        dailyRate: dailyRate,
        isActive: isActive,
      );

      final updatedZone = ParkingZone.fromJson(result);
      final index = _parkingZones.indexWhere((z) => z.id == zoneId);
      if (index != -1) {
        _parkingZones[index] = updatedZone;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createParkingSpot({
    required int parkingZoneId,
    required int type,
    required int? rowNumber,
    required int? columnNumber,
    required bool isAvailable,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.createParkingSpot(
        parkingZoneId: parkingZoneId,
        type: type,
        rowNumber: rowNumber,
        columnNumber: columnNumber,
        isAvailable: isAvailable,
      );

      final index = _parkingZones.indexWhere((z) => z.id == parkingZoneId);
      if (index != -1) {
        final response = await ApiService.searchParkingZones(
          page: 1,
          pageSize: 1000,
        );

        final zones =
            (response['results'] as List?)
                ?.map((z) => ParkingZone.fromJson(z as Map<String, dynamic>))
                .toList() ??
            [];

        final updatedZone = zones.firstWhere(
          (z) => z.id == parkingZoneId,
          orElse: () => _parkingZones[index],
        );

        _parkingZones[index] = updatedZone;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateParkingSpot({
    required int spotId,
    String? spotCode,
    int? type,
    int? rowNumber,
    int? columnNumber,
    bool? isAvailable,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.updateParkingSpot(
        spotId: spotId,
        spotCode: spotCode,
        type: type,
        rowNumber: rowNumber,
        columnNumber: columnNumber,
        isAvailable: isAvailable,
      );

      await searchParkingZones(includeSpots: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteParkingSpot(int spotId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.deleteParkingSpot(spotId);

      await searchParkingZones(includeSpots: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleParkingSpotActive({
    required int spotId,
    required bool isAvailable,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.toggleParkingSpotActive(
        spotId: spotId,
        isAvailable: isAvailable,
      );

      await searchParkingZones(includeSpots: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ParkingZone>> searchParkingZonesLive({String? name}) async {
    try {
      final result = await ApiService.searchParkingZones(
        name: name,
        pageSize: 1000,
      );
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((zone) => ParkingZone.fromJson(zone as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<List<City>> searchCitiesLive({String? name}) async {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
