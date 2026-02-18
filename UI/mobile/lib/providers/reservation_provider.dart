import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/api_service.dart';

class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> getUserReservations({required int userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getUserReservations(userId: userId);
      _reservations = (result['results'] as List)
          .map((e) => Reservation.fromJson(e))
          .toList();
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
