import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/request_models.dart';
import '../models/reservation_model.dart';
import '../services/api_service.dart';

class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalCount = 0;
  bool _hasMore = true;

  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<Reservation> createReservation(
    ReservationCreateRequest request,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reservation = await ApiService.createReservation(request);
      _reservations.add(reservation);
      notifyListeners();
      return reservation;
    } catch (e) {
      log('ReservationProvider.createReservation error: $e');
      _errorMessage = 'Došlo je do greške pri kreiranju rezervacije.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUserReservations({required int userId, int page = 1}) async {
    if (page == 1) {
      _isLoading = true;
      _reservations = [];
    }

    notifyListeners();

    try {
      final result = await ApiService.getUserReservations(
        userId: userId,
        page: page,
      );

        final newReservations = result.results;

        _totalCount = result.count;

      if (page == 1) {
        _reservations = newReservations;
      } else {
        _reservations.addAll(newReservations);
      }

      _hasMore = _reservations.length < _totalCount;
      _errorMessage = null;
    } catch (e) {
      log('ReservationProvider.getUserReservations error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju rezervacija.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelReservation(int reservationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.cancelReservation(reservationId);
      _reservations.removeWhere((r) => r.id == reservationId);
      notifyListeners();
      return true;
    } catch (e) {
      log('ReservationProvider.cancelReservation error: $e');
      _errorMessage = 'Došlo je do greške pri otkazivanju rezervacije.';
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
