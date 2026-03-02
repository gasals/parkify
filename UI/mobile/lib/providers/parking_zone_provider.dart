import 'package:flutter/material.dart';
import '../models/parking_zone_model.dart';
import '../services/api_service.dart';

class ParkingZoneProvider extends ChangeNotifier {
  List<ParkingZone> _parkingZones = [];
  ParkingZone? _selectedZone;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalCount = 0;

  List<ParkingZone> get parkingZones => _parkingZones;
  ParkingZone? get selectedZone => _selectedZone;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;

  Future<void> getParkingZones({
    int page = 1,
    int pageSize = 10,
    bool includeSpots = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getParkingZones(
        page: page,
        pageSize: pageSize,
        includeSpots: includeSpots,
      );

      final resultsList = result['results'] as List? ?? [];

      _parkingZones = resultsList
          .map((zone) => ParkingZone.fromJson(zone as Map<String, dynamic>))
          .toList();

      _totalCount = result['count'] ?? 0;
      _currentPage = page;

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getParkingZoneById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getParkingZoneById(id);
      _selectedZone = ParkingZone.fromJson(result);
      await getParkingSpots();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getParkingSpots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getParkingSpotsByZoneId(_selectedZone!.id);
      _selectedZone!.spots = (result['results'] as List)
          .map((spot) => ParkingSpot.fromJson(spot as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedZone() {
    _selectedZone = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
