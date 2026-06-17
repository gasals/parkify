import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/parking_zone_model.dart';
import '../models/parking_zone_recommendation_model.dart';
import '../services/api_service.dart';

class ParkingZoneProvider extends ChangeNotifier {
  List<ParkingZone> _parkingZones = [];
  List<ParkingZone> _recommendedZones = [];
  List<ParkingZoneRecommendation> _explainedRecommendedZones = [];
  ParkingZone? _selectedZone;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalCount = 0;

  List<ParkingZone> get parkingZones => _parkingZones;
  List<ParkingZone> get recommendedZones => _recommendedZones;
  List<ParkingZoneRecommendation> get explainedRecommendedZones =>
      _explainedRecommendedZones;
  ParkingZoneRecommendation? get topRecommendation =>
      _explainedRecommendedZones.isNotEmpty
      ? _explainedRecommendedZones.first
      : null;
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
      _parkingZones = result.results;
      _totalCount = result.count;
      _currentPage = page;

      notifyListeners();
    } catch (e) {
      log('ParkingZoneProvider.getParkingZones error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju parking zona.';
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
      _selectedZone = await ApiService.getParkingZoneById(id);
      await getParkingSpots();
    } catch (e) {
      log('ParkingZoneProvider.getParkingZoneById error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju parking zone.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getRecommendedZones({int count = 5}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final explainedResult =
          await ApiService.getExplainedRecommendedParkingZones(
            count: count,
          );

        _explainedRecommendedZones = explainedResult;

      _recommendedZones = _explainedRecommendedZones
          .map((item) => item.zone)
          .toList();
    } catch (e) {
      log(
        'ParkingZoneProvider.getRecommendedZones explained endpoint error: $e',
      );

      try {
        final result = await ApiService.getRecommendedParkingZones(
          count: count,
        );

        _recommendedZones = result;

        _explainedRecommendedZones = _recommendedZones
            .map(
              (zone) => ParkingZoneRecommendation(
                zone: zone,
                score: 0,
                reasons: const [],
              ),
            )
            .toList();
      } catch (fallbackError) {
        log(
          'ParkingZoneProvider.getRecommendedZones fallback error: $fallbackError',
        );
        _errorMessage = 'Došlo je do greške pri učitavanju preporučenih zona.';
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> getParkingSpots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getParkingSpotsByZoneId(
        _selectedZone!.id,
      );
      _selectedZone!.spots = result.results;
    } catch (e) {
      log('ParkingZoneProvider.getParkingSpots error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju parking mjesta.';
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
