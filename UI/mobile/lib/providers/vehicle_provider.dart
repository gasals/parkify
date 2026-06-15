import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/request_models.dart';
import '../models/vehicle_model.dart';
import '../services/api_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserVehicles(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getUserVehicles(userId);
      _vehicles = result.results;

      if (_vehicles.isNotEmpty && _selectedVehicle == null) {
        _selectedVehicle = _vehicles.first;
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      log('VehicleProvider.fetchUserVehicles error: $e');
      _errorMessage = 'Došlo je do greške pri učitavanju vozila.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle({
    required int userId,
    required String licensePlate,
    required VehicleCategory category,
    required String model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newVehicle = Vehicle(
        id: 0,
        userId: userId,
        licensePlate: licensePlate,
        category: category,
        model: model,
      );

      await ApiService.addVehicle(newVehicle);

      await fetchUserVehicles(userId);
      return true;
    } catch (e) {
      log('VehicleProvider.addVehicle error: $e');
      _errorMessage = 'Došlo je do greške pri dodavanju vozila.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVehicle({
    required int vehicleId,
    required int userId,
    required String licensePlate,
    required String model,
    required VehicleCategory category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVehicle = await ApiService.updateVehicle(
        vehicleId: vehicleId,
        request: VehicleUpdateRequest(
          userId: userId,
          licensePlate: licensePlate,
          model: model,
          category: category,
        ),
      );

      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
      }

      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = updatedVehicle;
      }

      return true;
    } catch (e) {
      log('VehicleProvider.updateVehicle error: $e');
      _errorMessage = 'Došlo je do greške pri ažuriranju vozila.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void clearSelection() {
    _selectedVehicle = null;
    notifyListeners();
  }
}
