import 'package:flutter/material.dart';
import '../models/parking_zone_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  Future<void> searchReservations({
    int? userId,
    int? parkingZoneId,
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.searchReservations(
        userId: userId,
        parkingZoneId: parkingZoneId,
        status: status,
        page: page,
        pageSize: pageSize,
      );

      final resultsList = result['results'] as List? ?? [];

      if (page == 1) {
        _reservations = [];
      }

      _reservations.addAll(
        resultsList
            .map((res) => Reservation.fromJson(res as Map<String, dynamic>))
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

  Future<bool> updateReservationStatus(int reservationId, int status) async {
    try {
      await ApiService.updateReservationStatus(reservationId, status);

      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final updated = _reservations[index];
        _reservations[index] = Reservation(
          id: updated.id,
          reservationCode: updated.reservationCode,
          userId: updated.userId,
          parkingZoneId: updated.parkingZoneId,
          parkingSpotId: updated.parkingSpotId,
          spotCode: updated.spotCode,
          parkingZoneName: updated.parkingZoneName,
          reservationStart: updated.reservationStart,
          reservationEnd: updated.reservationEnd,
          durationInHours: updated.durationInHours,
          status: status,
          isCheckedIn: updated.isCheckedIn,
          isCheckedOut: updated.isCheckedOut,
          calculatedPrice: updated.calculatedPrice,
          discountAmount: updated.discountAmount,
          finalPrice: updated.finalPrice,
          requiresDisabledSpot: updated.requiresDisabledSpot,
          notes: updated.notes,
          qrCodeData: updated.qrCodeData,
          created: updated.created,
          modified: DateTime.now(),
          checkInTime: updated.checkInTime,
          checkOutTime: updated.checkOutTime,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkInReservation(int reservationId) async {
    try {
      final result = await ApiService.checkInReservation(reservationId);
      final updatedReservation = Reservation.fromJson(result);

      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updatedReservation;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOutReservation(int reservationId) async {
    try {
      final result = await ApiService.checkOutReservation(reservationId);
      final updatedReservation = Reservation.fromJson(result);

      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updatedReservation;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<User>> getAllUsersList({int pageSize = 1000}) async {
    try {
      final result = await ApiService.getAllUsers(pageSize: pageSize);
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<List<User>> searchUsersLive({String? username, String? email}) async {
    try {
      final result = await ApiService.searchUsers(
        username: username,
        email: email,
        pageSize: 1000,
      );
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<List<ParkingZone>> getAllParkingZonesList({
    int pageSize = 1000,
  }) async {
    try {
      final result = await ApiService.searchParkingZones(pageSize: pageSize);
      final resultsList = result['results'] as List? ?? [];

      return resultsList
          .map((zone) => ParkingZone.fromJson(zone as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
