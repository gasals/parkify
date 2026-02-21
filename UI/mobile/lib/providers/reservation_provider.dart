import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/api_service.dart';

class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalCount = 0;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Reservation> createReservation(Map<String, dynamic> reservationData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.createReservation(reservationData);
      final reservation = Reservation.fromJson(result);
      _reservations.add(reservation);
      notifyListeners();
      return reservation;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUserReservations({
    required int userId,
    int page = 1,
  }) async {

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

      final newReservations = (result['results'] as List)
          .map((e) => Reservation.fromJson(e))
          .toList();

      _totalCount = result['count'];

      if (page == 1) {
        _reservations = newReservations;
      } else {
        _reservations.addAll(newReservations);
      }
      _hasMore = _reservations.length < _totalCount;

    } catch (e) {
      _errorMessage = e.toString();
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
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
