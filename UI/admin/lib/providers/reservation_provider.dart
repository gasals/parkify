import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
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

  Future<void> getAllReservations({
    int page = 1,
    int pageSize = 20,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getAllReservations(
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

  Future<void> getUserReservations({
    required int userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getUserReservations(
        userId: userId,
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
      await ApiService.checkInReservation(reservationId);
      
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
          status: updated.status,
          isCheckedIn: true,
          isCheckedOut: updated.isCheckedOut,
          calculatedPrice: updated.calculatedPrice,
          discountAmount: updated.discountAmount,
          finalPrice: updated.finalPrice,
          requiresDisabledSpot: updated.requiresDisabledSpot,
          notes: updated.notes,
          qrCodeData: updated.qrCodeData,
          created: updated.created,
          modified: DateTime.now(),
          checkInTime: DateTime.now(),
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

  Future<bool> checkOutReservation(int reservationId) async {
    try {
      await ApiService.checkOutReservation(reservationId);
      
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
          status: updated.status,
          isCheckedIn: updated.isCheckedIn,
          isCheckedOut: true,
          calculatedPrice: updated.calculatedPrice,
          discountAmount: updated.discountAmount,
          finalPrice: updated.finalPrice,
          requiresDisabledSpot: updated.requiresDisabledSpot,
          notes: updated.notes,
          qrCodeData: updated.qrCodeData,
          created: updated.created,
          modified: DateTime.now(),
          checkInTime: updated.checkInTime,
          checkOutTime: DateTime.now(),
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

  Future<bool> cancelReservation(int reservationId) async {
    try {
      await ApiService.cancelReservation(reservationId);
      await getAllReservations();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}