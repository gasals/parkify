import 'package:flutter/material.dart';
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
      final resultsList = result['results'] as List? ?? [];

      _vehicles = resultsList
          .map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList();

      if (_vehicles.isNotEmpty && _selectedVehicle == null) {
        _selectedVehicle = _vehicles.first;
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle({
    required int userId,
    required String licensePlate,
    required String category,
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
      _errorMessage = e.toString();
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
    required String category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updateVehicle(
        vehicleId: vehicleId,
        userId: userId,
        licensePlate: licensePlate,
        model: model,
        category: category,
      );

      final updatedVehicle = Vehicle.fromJson(result);

      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
      }

      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = updatedVehicle;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
